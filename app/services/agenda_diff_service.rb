class AgendaDiffService
  attr_reader :changes, :meeting

  def initialize(meeting, new_data)
    @meeting = meeting
    @new_data = new_data
    @changes = { sections: [] }
  end

  def call
    version = @meeting.current_version
    return self unless version

    existing_items = index_existing_items(version)
    new_items = index_new_items(@new_data)

    all_keys = (existing_items.keys + new_items.keys).uniq.sort_by { |k| k.split(".").map(&:to_i) }

    all_keys.each do |item_number|
      old_item = existing_items[item_number]
      new_item = new_items[item_number]

      if old_item && new_item
        diffs = compute_item_diff(old_item, new_item)
        if diffs.any?
          @changes[:sections] << {
            type: :modified,
            item_number: item_number,
            old: old_item,
            new: new_item,
            diffs: diffs
          }
        end
      elsif new_item
        @changes[:sections] << {
          type: :added,
          item_number: item_number,
          new: new_item
        }
      else
        @changes[:sections] << {
          type: :removed,
          item_number: item_number,
          old: old_item
        }
      end
    end

    self
  end

  def has_changes?
    @changes[:sections].any?
  end

  private

  def index_existing_items(version)
    items = {}
    version.agenda_sections.includes(:agenda_items).each do |section|
      section.agenda_items.each do |item|
        items[item.item_number] = {
          id: item.id,
          item_number: item.item_number,
          title: item.title,
          page_start: item.page_start,
          page_end: item.page_end,
          file_number: item.file_number,
          url: item.url,
          item_type: item.item_type,
          section_number: section.number,
          section_title: section.title,
          section_type: section.section_type
        }
      end
    end
    items
  end

  def index_new_items(data)
    items = {}
    (data["sections"] || []).each do |section|
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

  COMPARED_FIELDS = %i[title page_start page_end file_number url item_type].freeze

  def compute_item_diff(old_item, new_item)
    diffs = []
    COMPARED_FIELDS.each do |field|
      old_val = normalize_value(old_item[field])
      new_val = normalize_value(new_item[field])
      if old_val != new_val
        diffs << { field: field, old: old_item[field], new: new_item[field] }
      end
    end
    diffs
  end

  def normalize_value(val)
    return nil if val.nil?
    val.is_a?(String) ? val.strip.presence : val
  end
end
