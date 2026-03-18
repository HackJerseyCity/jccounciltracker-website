require "test_helper"

class AgendaPdfParserServiceTest < ActiveSupport::TestCase
  test "returns errors for invalid PDF" do
    invalid_io = StringIO.new("not a pdf")
    service = AgendaPdfParserService.new(invalid_io)
    result = service.call

    assert_nil result
    assert_not service.success?
    assert service.errors.any?
  end

  test "parser script exists" do
    assert File.exist?(AgendaPdfParserService::PARSER_SCRIPT),
      "parse_agenda.py should exist at #{AgendaPdfParserService::PARSER_SCRIPT}"
  end
end
