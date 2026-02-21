require "test_helper"

class MinutesImportServiceTest < ActiveSupport::TestCase
  def valid_minutes_data
    {
      "meeting" => { "type" => "regular", "date" => "2026-02-25" },
      "council_members" => [ "Ridley", "Lavarro" ],
      "items" => [
        {
          "item_number" => "3.1",
          "result" => "approved",
          "vote_tally" => "9-0",
          "votes" => { "Ridley" => "aye", "Lavarro" => "aye" }
        },
        {
          "item_number" => "10.1",
          "result" => "approved",
          "vote_tally" => "8-1",
          "votes" => { "Ridley" => "aye", "Lavarro" => "nay" }
        }
      ]
    }
  end

  test "successful import sets result and tally and creates votes" do
    service = MinutesImportService.new(valid_minutes_data).call

    assert service.success?
    assert_empty service.errors

    item = agenda_items(:ordinance_with_details).reload
    assert_equal "approved", item.result
    assert_equal "9-0", item.vote_tally
    assert_equal 2, item.votes.count

    resolution = agenda_items(:resolution_item).reload
    assert_equal "approved", resolution.result
    assert_equal "8-1", resolution.vote_tally
  end

  test "idempotent re-import updates without duplicating" do
    MinutesImportService.new(valid_minutes_data).call
    initial_vote_count = Vote.count

    # Re-import same data
    service = MinutesImportService.new(valid_minutes_data).call
    assert service.success?
    assert_equal initial_vote_count, Vote.count

    # Results still correct
    item = agenda_items(:ordinance_with_details).reload
    assert_equal "approved", item.result
    assert_equal "9-0", item.vote_tally
  end

  test "missing meeting returns error" do
    data = valid_minutes_data
    data["meeting"]["date"] = "2099-01-01"

    service = MinutesImportService.new(data).call
    assert_not service.success?
    assert service.errors.any? { |e| e.include?("No meeting found") }
  end

  test "missing council member returns error" do
    data = valid_minutes_data
    data["council_members"] << "UnknownPerson"

    service = MinutesImportService.new(data).call
    assert_not service.success?
    assert service.errors.any? { |e| e.include?("Unknown council members") }
  end

  test "unmatched item_number produces warning" do
    data = valid_minutes_data
    data["items"] << {
      "item_number" => "99.9",
      "result" => "approved",
      "vote_tally" => "9-0",
      "votes" => { "Ridley" => "aye" }
    }

    service = MinutesImportService.new(data).call
    assert service.success?
    assert service.warnings.any? { |w| w.include?("99.9") }
  end

  test "withdrawn items set result but create no votes" do
    data = {
      "meeting" => { "type" => "regular", "date" => "2026-02-25" },
      "council_members" => [ "Ridley" ],
      "items" => [
        {
          "item_number" => "3.1",
          "result" => "withdrawn",
          "vote_tally" => nil,
          "votes" => {}
        }
      ]
    }

    service = MinutesImportService.new(data).call
    assert service.success?

    item = agenda_items(:ordinance_with_details).reload
    assert_equal "withdrawn", item.result
    assert_nil item.vote_tally
    assert_equal 0, item.votes.count
  end

  test "transaction rolls back on error" do
    data = valid_minutes_data
    # Corrupt a vote position to cause a save! error
    data["items"][0]["votes"]["Ridley"] = "invalid_position"

    service = MinutesImportService.new(data).call
    assert_not service.success?

    # Result should not have been persisted
    item = agenda_items(:ordinance_with_details).reload
    assert_nil item.result
  end

  test "handles position-to-names vote format" do
    data = {
      "meeting" => { "type" => "regular", "date" => "2026-02-25" },
      "council_members" => [ "Ridley", "Lavarro" ],
      "items" => [
        {
          "item_number" => "3.1",
          "result" => "approved",
          "vote_tally" => "1-1",
          "votes" => { "aye" => [ "Ridley" ], "nay" => [ "Lavarro" ], "abstain" => [], "absent" => [] }
        }
      ]
    }

    service = MinutesImportService.new(data).call
    assert service.success?

    item = agenda_items(:ordinance_with_details).reload
    assert_equal 2, item.votes.count
    assert_equal "aye", item.votes.find_by(council_member: council_members(:ridley)).position
    assert_equal "nay", item.votes.find_by(council_member: council_members(:lavarro)).position
  end

  test "invalid JSON structure returns error" do
    service = MinutesImportService.new("not a hash").call
    assert_not service.success?
    assert service.errors.any? { |e| e.include?("Invalid JSON structure") }
  end

  test "re-import clears stale votes" do
    # First import with two voters
    MinutesImportService.new(valid_minutes_data).call
    item = agenda_items(:ordinance_with_details).reload
    assert_equal 2, item.votes.count

    # Re-import with only one voter
    data = {
      "meeting" => { "type" => "regular", "date" => "2026-02-25" },
      "council_members" => [ "Ridley" ],
      "items" => [
        {
          "item_number" => "3.1",
          "result" => "approved",
          "vote_tally" => "1-0",
          "votes" => { "Ridley" => "aye" }
        }
      ]
    }

    service = MinutesImportService.new(data).call
    assert service.success?

    item.reload
    assert_equal 1, item.votes.count
    assert_equal "Ridley", item.votes.first.council_member.last_name
  end
end
