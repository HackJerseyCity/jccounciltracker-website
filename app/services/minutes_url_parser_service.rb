require "nokogiri"

class MinutesUrlParserService
  attr_reader :errors

  def initialize(url)
    @url = url
    @errors = []
  end

  def call
    fetcher = CivicwebFetcherService.new(@url)

    meeting_info = fetcher.fetch_meeting_info
    unless meeting_info
      @errors.concat(fetcher.errors)
      return nil
    end

    html = fetcher.fetch_minutes_html
    unless html
      @errors.concat(fetcher.errors)
      return nil
    end

    parse_html(html, meeting_info)
  rescue StandardError => e
    @errors << "Parsing error: #{e.message}"
    nil
  end

  def success?
    @errors.empty?
  end

  private

  def parse_html(html, meeting_info)
    doc = Nokogiri::HTML(html)
    lines = extract_lines_from_paragraphs(doc)

    meeting_date = parse_meeting_date(lines, meeting_info)
    meeting_type = meeting_info[:meeting_type] || "regular"

    council_members = extract_roster(lines)
    items = parse_items(lines)

    {
      "meeting" => {
        "type" => meeting_type,
        "date" => meeting_date
      },
      "council_members" => council_members,
      "items" => items
    }
  end

  def extract_lines_from_paragraphs(doc)
    doc.css("p").filter_map do |p|
      text = p.text.gsub(/[[:space:]]+/, " ").strip
      text unless text.empty? || text == "\u00a0"
    end
  end

  def parse_meeting_date(lines, meeting_info)
    lines.each do |line|
      match = line.match(/(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\s+(\w+ \d{1,2},?\s+\d{4})/i)
      if match
        begin
          return Date.parse(match[1]).strftime("%Y-%m-%d")
        rescue Date::Error
          next
        end
      end
    end

    if meeting_info[:date]
      begin
        return Date.parse(meeting_info[:date]).strftime("%Y-%m-%d")
      rescue Date::Error
        nil
      end
    end

    @errors << "Could not determine meeting date."
    nil
  end

  def extract_roster(lines)
    members = []
    # Roster appears in the header area (first ~25 lines)
    lines.first(25).each do |line|
      # Match "Name, Councilperson" patterns (with ward/at-large suffixes)
      name_match = line.match(/^(.+?),?\s+Councilperson/i)
      if name_match
        name = name_match[1].strip
        # Extract last name for matching (handle "Jr.", suffixes)
        last_name = name.split(/\s+/).reject { |p| p.match?(/^(jr|sr|ii|iii|iv)\.?,?$/i) }.last&.delete(",")
        members << last_name if last_name
      end
    end
    members.uniq
  end

  def parse_items(lines)
    items = []
    i = 0

    while i < lines.length
      line = lines[i]

      # Look for vote result patterns: "Adopted 9-0", "Approved 8-1", etc.
      vote_match = line.match(/^(adopted|approved|defeated|tabled|withdrawn|received and filed|postponed)\s+(\d+-\d+(?:-\d+)?)?/i)

      if vote_match && i > 0
        result = vote_match[1].downcase
        tally = vote_match[2]

        # Look backward for item number
        item_number = find_item_number_backward(lines, i)

        if item_number
          item = {
            "item_number" => item_number,
            "result" => result,
            "vote_tally" => tally,
            "votes" => parse_vote_detail(lines, i)
          }
          items << item
        end
      end

      i += 1
    end

    items
  end

  def find_item_number_backward(lines, current_index)
    (current_index - 1).downto([ current_index - 10, 0 ].max) do |j|
      match = lines[j].match(/^(\d+\.\d+)/)
      return match[1] if match
    end
    nil
  end

  def parse_vote_detail(lines, vote_line_index)
    votes = { "aye" => [], "nay" => [], "abstain" => [], "absent" => [] }

    # Look at subsequent lines for vote details
    ((vote_line_index + 1)..[ vote_line_index + 5, lines.length - 1 ].min).each do |j|
      line = lines[j]
      break if line.match?(/^\d+\./) # Next item

      if line.match?(/council/i)
        # Parse "Councilperson Name: nay" patterns
        line.scan(/council\s*(?:person|woman|man|member|president(?:\s+pro\s+temp)?)\s+(?:at\s+large\s+)?(\w+)(?::\s*(\w+))?/i).each do |name, position|
          position = (position || "aye").downcase
          category = case position
          when "nay", "no" then "nay"
          when "abstain", "abstained" then "abstain"
          when "absent" then "absent"
          else "aye"
          end
          votes[category] << name
        end
      end
    end

    votes
  end
end
