class MinutesImportService
  attr_reader :meeting, :errors, :warnings

  def initialize(data)
    @data = data
    @meeting = nil
    @errors = []
    @warnings = []
    @council_members = {}
  end

  def call
    validate_structure!
    return self unless @errors.empty?

    find_meeting!
    return self unless @errors.empty?

    resolve_council_members!
    return self unless @errors.empty?

    ActiveRecord::Base.transaction do
      import_items!
      raise ActiveRecord::Rollback if @errors.any?
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      @errors << e.message
      raise ActiveRecord::Rollback
    end

    self
  end

  def success?
    @errors.empty? && @meeting.present?
  end

  private

  def validate_structure!
    unless @data.is_a?(Hash) && @data["meeting"].is_a?(Hash) && @data["items"].is_a?(Array)
      @errors << "Invalid JSON structure: must contain 'meeting' object and 'items' array"
    end
  end

  def find_meeting!
    meeting_data = @data["meeting"]
    @meeting = Meeting.find_by(
      date: meeting_data["date"],
      meeting_type: meeting_data["type"]
    )

    unless @meeting
      @errors << "No meeting found for date #{meeting_data['date']} and type #{meeting_data['type']}"
    end
  end

  def resolve_council_members!
    last_names = (@data["council_members"] || []).map { |name| name.to_s.strip }
    return if last_names.empty?

    all_members = CouncilMember.all.index_by { |cm| normalize_name(cm.last_name) }

    missing = []
    last_names.each do |name|
      normalized = normalize_name(name)
      member = all_members[normalized]
      if member
        @council_members[name.downcase] = member
      else
        missing << name
      end
    end

    if missing.any?
      @errors << "Unknown council members: #{missing.join(', ')}"
    end
  end

  def normalize_name(name)
    name.downcase.gsub(/\s+(jr|sr|ii|iii|iv)\.?\s*$/i, "").strip
  end

  def import_items!
    agenda_items_by_number = @meeting.agenda_items.index_by(&:item_number)

    @data["items"].each do |item_data|
      item_number = item_data["item_number"]
      agenda_item = agenda_items_by_number[item_number]

      unless agenda_item
        @warnings << "No matching agenda item for item_number #{item_number}"
        next
      end

      agenda_item.update!(
        result: item_data["result"],
        vote_tally: item_data["vote_tally"]
      )

      import_votes_for_item(agenda_item, item_data["votes"] || {})
    end
  end

  def import_votes_for_item(agenda_item, votes_hash)
    if votes_hash.empty?
      agenda_item.votes.delete_all
      return
    end

    # Normalize votes: accept both { "aye": ["Name", ...] } and { "Name": "aye" }
    normalized = normalize_votes(votes_hash)

    # Clear stale votes for this item that aren't in the new data
    incoming_member_ids = normalized.keys.filter_map { |name| @council_members[name.downcase]&.id }
    agenda_item.votes.where.not(council_member_id: incoming_member_ids).delete_all

    normalized.each do |last_name, position|
      council_member = @council_members[last_name.downcase]
      next unless council_member

      vote = agenda_item.votes.find_or_initialize_by(council_member: council_member)
      vote.position = position
      vote.save!
    end
  end

  def normalize_votes(votes_hash)
    # Format: { "aye": ["Ridley", "Lavarro"], "nay": ["Smith"] }
    if votes_hash.values.first.is_a?(Array)
      result = {}
      votes_hash.each do |position, names|
        names.each { |name| result[name] = position }
      end
      result
    else
      # Format: { "Ridley": "aye", "Lavarro": "nay" }
      votes_hash
    end
  end
end
