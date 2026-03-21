class AgendaApplyChangesService
  attr_reader :meeting, :errors

  def initialize(meeting, new_data, accepted_changes)
    @meeting = meeting
    @new_data = new_data
    @accepted_changes = accepted_changes # array of item_numbers to accept
    @errors = []
  end

  def call
    version = @meeting.current_version
    unless version
      @errors << "No existing version found."
      return self
    end

    ActiveRecord::Base.transaction do
      apply_accepted_changes(version)
      raise ActiveRecord::Rollback if @errors.any?
    end

    self
  end

  def success?
    @errors.empty?
  end

  private

  def apply_accepted_changes(version)
    existing_items = version.agenda_items.index_by(&:item_number)
    new_items_by_number = index_new_items

    @accepted_changes.each do |item_number|
      old_item = existing_items[item_number]
      new_item = new_items_by_number[item_number]

      if old_item && new_item
        update_item(old_item, new_item)
      elsif new_item
        add_item(version, new_item)
      elsif old_item
        remove_item(old_item)
      end
    end
  end

  def update_item(old_item, new_data)
    old_item.update!(
      title: new_data[:title],
      page_start: new_data[:page_start],
      page_end: new_data[:page_end],
      file_number: new_data[:file_number],
      url: new_data[:url],
      item_type: new_data[:item_type]
    )
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Failed to update #{old_item.item_number}: #{e.message}"
  end

  def add_item(version, new_data)
    section = find_or_create_section(version, new_data)
    return unless section

    position = (section.agenda_items.maximum(:position) || -1) + 1
    item = section.agenda_items.build(
      item_number: new_data[:item_number],
      title: new_data[:title],
      page_start: new_data[:page_start],
      page_end: new_data[:page_end],
      file_number: new_data[:file_number],
      url: new_data[:url],
      item_type: new_data[:item_type],
      position: position
    )

    unless item.save
      @errors << "Failed to add #{new_data[:item_number]}: #{item.errors.full_messages.join(', ')}"
    end
  end

  def remove_item(old_item)
    old_item.votes.delete_all
    old_item.destroy!
  rescue ActiveRecord::RecordNotDestroyed => e
    @errors << "Failed to remove #{old_item.item_number}: #{e.message}"
  end

  def find_or_create_section(version, item_data)
    section_number = item_data[:section_number]
    section = version.agenda_sections.find_by(number: section_number)
    return section if section

    section_type = item_data[:section_type]
    return nil unless AgendaSection.section_types.key?(section_type)

    section = version.agenda_sections.create(
      number: section_number,
      title: item_data[:section_title],
      section_type: section_type
    )

    unless section.persisted?
      @errors << "Failed to create section #{section_number}: #{section.errors.full_messages.join(', ')}"
      return nil
    end

    section
  end

  def index_new_items
    items = {}
    (@new_data["sections"] || []).each do |section|
      (section["items"] || []).each do |item|
        items[item["item_number"]] = {
          item_number: item["item_number"],
          title: item["title"],
          page_start: item["page_start"],
          page_end: item["page_end"],
          file_number: item["file_number"],
          url: item["url"],
          item_type: item["item_type"],
          section_number: section["number"],
          section_title: section["title"],
          section_type: section["type"]
        }
      end
    end
    items
  end
end
