require "nokogiri"

class AgendaUrlParserService
  attr_reader :errors

  SECTION_TYPES = {
    "ordinance - first reading" => "ordinance_first_reading",
    "ordinance first reading" => "ordinance_first_reading",
    "ordinances - first reading" => "ordinance_first_reading",
    "ordinance hearing - second reading" => "ordinance_second_reading",
    "ordinance hearing second reading" => "ordinance_second_reading",
    "ordinances hearing - second reading" => "ordinance_second_reading",
    "public request for hearing" => "public_request_for_hearing",
    "petitions and communications" => "petitions_communications",
    "petitions & communications" => "petitions_communications",
    "officers communications" => "reports_of_directors",
    "reports of directors" => "reports_of_directors",
    "claims" => "resolutions",
    "resolutions" => "resolutions",
    "adjournment" => nil
  }.freeze

  ITEM_TYPES = {
    "ordinance_first_reading" => "ordinance",
    "ordinance_second_reading" => "ordinance",
    "resolutions" => "resolution",
    "petitions_communications" => "other",
    "public_request_for_hearing" => "other",
    "reports_of_directors" => "other"
  }.freeze

  def initialize(url)
    @url = url
    @errors = []
  end

  def call
    fetcher = CivicwebFetcherService.new(@url)

    html = fetcher.fetch_agenda_html
    unless html
      @errors.concat(fetcher.errors)
      return nil
    end

    meeting_info = fetcher.fetch_meeting_info
    unless meeting_info
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
    links = extract_links(doc)
    section_headers = extract_section_headers(doc)

    meeting_date = parse_meeting_date(lines, meeting_info)
    meeting_type = meeting_info[:meeting_type] || "regular"

    sections = parse_sections(lines, links, section_headers)

    {
      "meeting" => {
        "type" => meeting_type,
        "date" => meeting_date
      },
      "agenda_pages" => nil,
      "sections" => sections
    }
  end

  def extract_lines_from_paragraphs(doc)
    doc.css("p").filter_map do |p|
      text = p.text.gsub(/[[:space:]]+/, " ").strip
      text unless text.empty? || text == "\u00a0"
    end
  end

  def extract_section_headers(doc)
    headers = {}
    doc.css("tr").each do |tr|
      tds = tr.css("> td")
      next if tds.length < 2

      first_text = tds[0].text.strip
      next unless first_text.match?(/^\d+\.$/)

      section_number = first_text.chomp(".").to_i
      title_text = (tds[1].at_css("h2, span") || tds[1]).text.strip
      is_claims = title_text.strip.downcase == "claims"
      section_type = classify_section(title_text)

      if section_type
        headers[section_number] = { title: title_text, type: section_type, claims: is_claims }
      end
    end
    headers
  end

  def extract_links(doc)
    links = {}
    doc.css("a[href*='document']").each do |a|
      href = a["href"]
      text = a.text.strip
      next if text.empty? || href.nil?

      file_match = text.match(/^((?:Ord|Res)\.\s*\d{2}-\d{3})/)
      if file_match
        file_number = file_match[1]
        full_url = make_absolute_url(href)
        links[file_number] = full_url
      end
    end
    links
  end

  def make_absolute_url(href)
    if href.start_with?("/")
      "https://#{CivicwebFetcherService::BASE_HOST}#{href}"
    else
      href
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

  def parse_sections(lines, links, section_headers)
    sections = []
    current_section = nil
    current_item = nil
    pending_pages = nil
    i = 0

    while i < lines.length
      line = lines[i]

      # Detect section header: a line like "3." that matches a known section
      if line.match?(/^\d+\.$/)
        section_number = line.chomp(".").to_i
        header = section_headers[section_number]

        if header
          save_current_item(current_section, current_item)
          current_item = nil
          pending_pages = nil

          current_section = {
            "number" => section_number,
            "title" => header[:title],
            "type" => header[:type],
            "claims" => header[:claims],
            "items" => []
          }
          sections << current_section
          i += 1
          next
        end
      end

      # Detect item number: "3.1" or "10.15"
      if line.match?(/^\d+\.\d+$/) && current_section
        save_current_item(current_section, current_item)

        current_item = {
          "item_number" => line,
          "title" => "",
          "page_start" => pending_pages&.first,
          "page_end" => pending_pages&.last,
          "file_number" => nil,
          "item_type" => current_section["claims"] ? "claims" : (ITEM_TYPES[current_section["type"]] || "other"),
          "url" => nil
        }
        pending_pages = nil
        i += 1
        next
      end

      # Detect page range: "11 - 17" or "373 - 378"
      page_match = line.match(/^(\d+)\s*-\s*(\d+)$/)
      if page_match && current_section
        pending_pages = [ page_match[1].to_i, page_match[2].to_i ]
        i += 1
        next
      end

      # Detect file number reference: "Ord. 26-001 - Pdf" or "Res. 26-027 - Withdrawn - Pdf"
      file_match = line.match(/^((?:Ord|Res)\.\s*\d{2}-\d{3})\s*-\s*(?:Withdrawn\s*-\s*)?Pdf$/i)
      if file_match && current_item
        file_number = file_match[1]
        current_item["file_number"] = file_number
        current_item["url"] = links[file_number]
        i += 1
        next
      end

      # Skip noise lines
      if line == "None" || line == "Late Item" || line.match?(/^&nbsp;?$/)
        i += 1
        next
      end

      # Title line for the current item
      if current_item
        if current_item["title"].empty?
          current_item["title"] = line
        elsif !line.match?(/^\d/)
          current_item["title"] = "#{current_item['title']} #{line}".strip
        end
      end

      i += 1
    end

    save_current_item(current_section, current_item)

    # Remove internal tracking keys
    sections.each { |s| s.delete("claims") }
    sections
  end

  def save_current_item(section, item)
    return unless section && item
    return if item["title"].blank? && item["file_number"].blank?
    section["items"] << item
  end

  def classify_section(title)
    normalized = title.strip.downcase.gsub(/[^a-z\s&]/, "").squeeze(" ")
    SECTION_TYPES.each do |pattern, type|
      return type if normalized.include?(pattern)
    end
    nil
  end
end
