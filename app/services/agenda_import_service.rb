class AgendaImportService
  attr_reader :meeting, :errors

  def initialize(data)
    @data = data
    @meeting = nil
    @errors = []
  end

  def call
    validate_structure!
    return self unless @errors.empty?

    ActiveRecord::Base.transaction do
      @meeting = build_meeting
      unless @meeting.save
        @errors.concat(@meeting.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      build_sections_and_items
      raise ActiveRecord::Rollback if @errors.any?
    end

    @meeting = nil if @errors.any?
    self
  end

  def success?
    @errors.empty? && @meeting.present?
  end

  private

  def validate_structure!
    unless @data.is_a?(Hash) && @data["meeting"].is_a?(Hash) && @data["sections"].is_a?(Array)
      @errors << "Invalid JSON structure: must contain 'meeting' object and 'sections' array"
    end
  end

  def build_meeting
    meeting_data = @data["meeting"]
    Meeting.new(
      date: meeting_data["date"],
      meeting_type: meeting_data["type"],
      agenda_pages: @data["agenda_pages"]
    )
  end

  def build_sections_and_items
    @data["sections"].each do |section_data|
      section = @meeting.agenda_sections.build(
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
