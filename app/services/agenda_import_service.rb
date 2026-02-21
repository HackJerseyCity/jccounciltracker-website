class AgendaImportService
  attr_reader :meeting, :agenda_version, :errors

  def initialize(data)
    @data = data
    @meeting = nil
    @agenda_version = nil
    @errors = []
  end

  def call
    validate_structure!
    return self unless @errors.empty?

    ActiveRecord::Base.transaction do
      find_or_create_meeting
      unless @meeting.persisted? || @meeting.save
        @errors.concat(@meeting.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      build_agenda_version
      unless @agenda_version.save
        @errors.concat(@agenda_version.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      build_sections_and_items
      raise ActiveRecord::Rollback if @errors.any?
    end

    if @errors.any?
      @meeting = nil
      @agenda_version = nil
    end
    self
  end

  def success?
    @errors.empty? && @meeting.present?
  end

  def new_version?
    @agenda_version&.version_number.to_i > 1
  end

  private

  def validate_structure!
    unless @data.is_a?(Hash) && @data["meeting"].is_a?(Hash) && @data["sections"].is_a?(Array)
      @errors << "Invalid JSON structure: must contain 'meeting' object and 'sections' array"
    end
  end

  def find_or_create_meeting
    meeting_data = @data["meeting"]
    @meeting = Meeting.find_or_initialize_by(
      date: meeting_data["date"],
      meeting_type: meeting_data["type"]
    )
  end

  def build_agenda_version
    next_version = (@meeting.agenda_versions.maximum(:version_number) || 0) + 1
    @agenda_version = @meeting.agenda_versions.build(
      version_number: next_version,
      agenda_pages: @data["agenda_pages"]
    )
  end

  def build_sections_and_items
    @data["sections"].each do |section_data|
      section = @agenda_version.agenda_sections.build(
        number: section_data["number"],
        title: section_data["title"],
        section_type: section_data["type"]
      )

      unless section.save
        @errors.concat(section.errors.full_messages)
        next
      end

      (section_data["items"] || []).each_with_index do |item_data, index|
        item = section.agenda_items.build(
          item_number: item_data["item_number"],
          title: item_data["title"],
          page_start: item_data["page_start"],
          page_end: item_data["page_end"],
          file_number: item_data["file_number"],
          item_type: item_data["item_type"],
          url: item_data["url"],
          position: index
        )

        unless item.save
          @errors.concat(item.errors.full_messages)
        end
      end
    end
  end
end
