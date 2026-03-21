require "net/http"
require "uri"
require "nokogiri"

class CivicwebFetcherService
  attr_reader :errors

  BASE_HOST = "cityofjerseycity.civicweb.net"

  def initialize(url)
    @url = url
    @errors = []
  end

  def fetch_agenda_html
    doc = fetch_meeting_page
    return nil unless doc

    pdf_doc_id = extract_pdf_document_id(doc)
    unless pdf_doc_id
      @errors << "Could not find agenda PDF link on the meeting page."
      return nil
    end

    html_doc_id = pdf_doc_id + 1
    fetch_document_html(html_doc_id)
  end

  def fetch_meeting_info
    doc = fetch_meeting_page
    return nil unless doc

    meeting_id = extract_meeting_id
    date_text = extract_selected_meeting_date(doc, meeting_id)
    meeting_type = extract_meeting_type(doc, meeting_id)

    { meeting_id: meeting_id, date: date_text, meeting_type: meeting_type }
  end

  def success?
    @errors.empty?
  end

  private

  def fetch_meeting_page
    uri = URI.parse(@url)
    unless uri.host&.include?("civicweb.net")
      @errors << "URL must be a CivicWeb meeting page."
      return nil
    end

    response = http_get(uri)
    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch meeting page: HTTP #{response.code}"
      return nil
    end

    Nokogiri::HTML(response.body)
  rescue URI::InvalidURIError
    @errors << "Invalid URL format."
    nil
  rescue StandardError => e
    @errors << "Failed to fetch meeting page: #{e.message}"
    nil
  end

  def extract_pdf_document_id(doc)
    link = doc.at_css("#ctl00_MainContent_DocumentPrintVersion")
    return nil unless link

    href = link["href"]
    return nil unless href

    match = href.match(%r{/document/(\d+)/})
    match ? match[1].to_i : nil
  end

  def extract_meeting_id
    uri = URI.parse(@url)
    params = URI.decode_www_form(uri.query || "").to_h
    params["Id"]&.to_i
  end

  def extract_selected_meeting_date(doc, meeting_id)
    button = doc.at_css("#ctl00_MainContent_MeetingButton#{meeting_id}")
    return nil unless button

    date_div = button.at_css(".meeting-list-item-button-date")
    date_div&.text&.strip
  end

  def extract_meeting_type(doc, meeting_id)
    button = doc.at_css("#ctl00_MainContent_MeetingButton#{meeting_id}")
    return "regular" unless button

    divs = button.css("div")
    type_text = divs.last&.text&.strip&.downcase || ""

    if type_text.include?("special")
      "special"
    elsif type_text.include?("caucus")
      "caucus"
    elsif type_text.include?("reorganization")
      "reorganization"
    else
      "regular"
    end
  end

  def fetch_document_html(doc_id)
    uri = URI.parse("https://#{BASE_HOST}/document/#{doc_id}")
    response = http_get(uri)

    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch HTML document #{doc_id}: HTTP #{response.code}"
      return nil
    end

    content_type = response["content-type"] || ""
    unless content_type.include?("text/html")
      @errors << "Document #{doc_id} is not HTML (#{content_type}). The HTML version may not be available."
      return nil
    end

    response.body
  rescue StandardError => e
    @errors << "Failed to fetch document: #{e.message}"
    nil
  end

  def http_get(uri, redirect_limit = 5)
    raise "Too many redirects" if redirect_limit == 0

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "CouncilTracker/1.0"

    response = http.request(request)

    if response.is_a?(Net::HTTPRedirection)
      location = response["location"]
      location = "https:#{location}" if location.start_with?("//")
      new_uri = URI.parse(location)
      new_uri = URI.join("#{uri.scheme}://#{uri.host}", location) unless new_uri.host
      return http_get(new_uri, redirect_limit - 1)
    end

    response
  end
end
