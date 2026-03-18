class MinutesPdfParserService
  attr_reader :errors

  PARSER_SCRIPT = Rails.root.join("lib", "parsers", "parse_minutes.py").to_s

  def initialize(pdf_io)
    @pdf_io = pdf_io
    @errors = []
  end

  def call
    tempfile = write_to_tempfile
    output_file = Tempfile.new([ "minutes_parsed", ".json" ])

    stdout, stderr, status = Open3.capture3(
      "python3", PARSER_SCRIPT, tempfile.path, output_file.path
    )

    unless status.success?
      @errors << "PDF parsing failed: #{stderr.presence || stdout}"
      return nil
    end

    JSON.parse(File.read(output_file.path))
  rescue Errno::ENOENT => e
    @errors << "Python 3 is not installed. PDF parsing requires python3 and PyMuPDF."
    nil
  rescue JSON::ParserError => e
    @errors << "Parser produced invalid JSON: #{e.message}"
    nil
  ensure
    tempfile&.close!
    output_file&.close!
  end

  def success?
    @errors.empty?
  end

  private

  def write_to_tempfile
    temp = Tempfile.new([ "minutes_upload", ".pdf" ])
    temp.binmode
    if @pdf_io.respond_to?(:read)
      temp.write(@pdf_io.read)
      @pdf_io.rewind if @pdf_io.respond_to?(:rewind)
    else
      temp.write(File.binread(@pdf_io))
    end
    temp.flush
    temp
  end
end
