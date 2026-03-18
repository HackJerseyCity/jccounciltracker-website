require "test_helper"

class MinutesPdfParserServiceTest < ActiveSupport::TestCase
  test "returns errors for invalid PDF" do
    invalid_io = StringIO.new("not a pdf")
    service = MinutesPdfParserService.new(invalid_io)
    result = service.call

    assert_nil result
    assert_not service.success?
    assert service.errors.any?
  end

  test "parser script exists" do
    assert File.exist?(MinutesPdfParserService::PARSER_SCRIPT),
      "parse_minutes.py should exist at #{MinutesPdfParserService::PARSER_SCRIPT}"
  end
end
