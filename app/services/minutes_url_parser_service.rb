require "nokogiri"
require "net/http"

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

    html = fetch_minutes_html(fetcher)
    unless html
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

  def fetch_minutes_html(fetcher)
    # Minutes HTML is typically at PDF document ID + 1, but we need
    # to find the minutes PDF first. The meeting page only shows the
    # agenda PDF link. For now, try agenda PDF ID + 3 (common offset
    # for minutes HTML: agenda PDF, agenda HTML, minutes PDF, minutes HTML).
    # If that fails, report that minutes are not available via URL.
    html = fetcher.fetch_agenda_html
    unless html
      @errors.concat(fetcher.errors)
      return nil
    end

    # Parse the agenda HTML to check the title confirms it's an agenda
    doc = Nokogiri::HTML(html)
    title = doc.at_css("title")&.text || ""

    unless title.downcase.include?("agenda")
      @errors << "Could not locate agenda document to derive minutes URL."
      return nil
    end

    # Derive minutes document IDs from the agenda PDF ID
    # Agenda PDF = N, Agenda HTML = N+1
    # Minutes PDF and HTML are at different offsets - we need to search
    fetcher_page = CivicwebFetcherService.new(@url)
    page_doc = Nokogiri::HTML(fetch_raw_page)
    pdf_link = page_doc.at_css("#ctl00_MainContent_DocumentPrintVersion")

    unless pdf_link
      @errors << "Could not find document links on the meeting page."
      return nil
    end

    pdf_match = pdf_link["href"]&.match(%r{/document/(\d+)/})
    unless pdf_match
      @errors << "Could not extract document ID from meeting page."
      return nil
    end

    base_id = pdf_match[1].to_i

    # Search for minutes HTML document in a reasonable range
    # The minutes are typically generated after the agenda documents
    (base_id + 2..base_id + 10).each do |doc_id|
      candidate_html = fetch_document(doc_id)
      next unless candidate_html

      candidate_doc = Nokogiri::HTML(candidate_html)
      candidate_title = candidate_doc.at_css("title")&.text || ""

      if candidate_title.downcase.include?("minutes")
        return candidate_html
      end
    end

    @errors << "Minutes HTML document not found. Minutes may not be published yet for this meeting."
    nil
  end

  def fetch_raw_page
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "CouncilTracker/1.0"
    response = http.request(request)
    response.body
  end

  def fetch_document(doc_id)
    uri = URI.parse("https://#{CivicwebFetcherService::BASE_HOST}/document/#{doc_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "CouncilTracker/1.0"
    response = http.request(request)

    return nil unless response.is_a?(Net::HTTPSuccess)
    return nil unless (response["content-type"] || "").include?("text/html")

    # Check it's not a 404 page or login redirect
    body = response.body
    return nil if body.include?("404") && body.include?("Object moved")

    body
  rescue StandardError
    nil
  end

  def parse_html(html, meeting_info)
    doc = Nokogiri::HTML(html)
    text_lines = extract_text_lines(doc)

    meeting_date = parse_meeting_date(text_lines, meeting_info)
    meeting_type = meeting_info[:meeting_type] || "regular"

    council_members = extract_roster(text_lines)
    items = parse_items(text_lines)

    {
      "meeting" => {
        "type" => meeting_type,
        "date" => meeting_date
      },
      "council_members" => council_members,
      "items" => items
    }
  end

  def extract_text_lines(doc)
    body = doc.at_css("body")
    return [] unless body

    text = body.inner_text
    lines = text.split("\n").map { |l| l.gsub(/[[:space:]]+/, " ").strip }.reject(&:empty?)
    lines.reject { |l| l == "\u00a0" }
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
    lines.each do |line|
      if line.match?(/council\s*(?:person|woman|man|member|president)/i)
        name_match = line.match(/^(.+?),?\s+council/i)
        members << name_match[1].strip if name_match
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
