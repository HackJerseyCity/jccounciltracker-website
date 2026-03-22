require "net/http"
require "uri"
require "nokogiri"
require "json"

class CivicwebFetcherService
  attr_reader :errors

  BASE_HOST = "cityofjerseycity.civicweb.net"

  # DocumentType constants from CivicWeb packageDocumentTypes
  AGENDA_HTML  = 1  # publishedAgendaOpenHtml
  AGENDA_PDF   = 4  # publishedAgendaOpenPdf
  MINUTES_HTML = 9  # publishedMinutesOpenHtml
  MINUTES_PDF  = 10 # publishedMinutesOpenPdf

  def initialize(url)
    @url = url
    @errors = []
  end

  def fetch_agenda_html
    doc_id = find_document_id(AGENDA_HTML)
    unless doc_id
      @errors << "Agenda HTML document not found for this meeting."
      return nil
    end
    fetch_document_html(doc_id)
  end

  def fetch_minutes_html
    doc_id = find_document_id(MINUTES_HTML)
    unless doc_id
      @errors << "Minutes HTML document not found. Minutes may not be published yet for this meeting."
      return nil
    end
    fetch_document_html(doc_id)
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

  def find_document_id(document_type)
    meeting_id = extract_meeting_id
    unless meeting_id
      @errors << "Could not extract meeting ID from URL."
      return nil
    end

    documents = fetch_meeting_documents(meeting_id)
    return nil unless documents

    doc = documents.find { |d| d["DocumentType"] == document_type }
    doc&.dig("Id")
  end

  def fetch_meeting_documents(meeting_id)
    uri = URI.parse("https://#{BASE_HOST}/Services/MeetingsService.svc/meetings/#{meeting_id}/meetingDocuments")
    response = http_get(uri)

    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch meeting documents API: HTTP #{response.code}"
      return nil
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    @errors << "Invalid response from meeting documents API."
    nil
  rescue StandardError => e
    @errors << "Failed to fetch meeting documents: #{e.message}"
    nil
  end

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
      @errors << "Document #{doc_id} is not HTML (#{content_type})."
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
    request["Accept"] = "application/json"

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
