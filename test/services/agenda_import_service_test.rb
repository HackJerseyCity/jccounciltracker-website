require "test_helper"

class AgendaImportServiceTest < ActiveSupport::TestCase
  def valid_data
    {
      "meeting" => { "type" => "special", "date" => "2026-03-15" },
      "agenda_pages" => 5,
      "sections" => [
        {
          "number" => 1,
          "title" => "REGULAR MEETING",
          "type" => "regular_meeting",
          "items" => []
        },
        {
          "number" => 2,
          "title" => "ORDINANCE - FIRST READING",
          "type" => "ordinance_first_reading",
          "items" => [
            {
              "item_number" => "2.1",
              "title" => "An Ordinance amending Chapter 160",
              "page_start" => 10,
              "page_end" => 13,
              "file_number" => "Ord. 26-009",
              "item_type" => "ordinance",
              "url" => "http://example.com/ord.pdf"
            },
            {
              "item_number" => "2.2",
              "title" => "A second ordinance",
              "page_start" => nil,
              "page_end" => nil,
              "file_number" => nil,
              "item_type" => "ordinance",
              "url" => nil
            }
          ]
        },
        {
          "number" => 3,
          "title" => "RESOLUTIONS",
          "type" => "resolutions",
          "items" => [
            {
              "item_number" => "3.1",
              "title" => "A Resolution designating April as Native Plant Month",
              "page_start" => 20,
              "page_end" => 22,
              "file_number" => "Res. 26-068",
              "item_type" => "resolution",
              "url" => "http://example.com/res.pdf"
            }
          ]
        }
      ]
    }
  end

  def existing_meeting_data
    {
      "meeting" => { "type" => "regular", "date" => "2026-02-25" },
      "agenda_pages" => 12,
      "sections" => [
        {
          "number" => 1,
          "title" => "UPDATED SECTION",
          "type" => "regular_meeting",
          "items" => []
        }
      ]
    }
  end

  test "successful import creates meeting, version, sections, and items" do
    service = AgendaImportService.new(valid_data)

    assert_difference [ "Meeting.count", "AgendaVersion.count" ], 1 do
      service.call
    end

    assert service.success?
    assert_not service.new_version?
    assert_equal "special", service.meeting.meeting_type
    assert_equal Date.new(2026, 3, 15), service.meeting.date
    assert_equal 5, service.agenda_version.agenda_pages
    assert_equal 1, service.agenda_version.version_number
    assert_equal 3, service.agenda_version.agenda_sections.count
    assert_equal 3, service.agenda_version.agenda_items.count
  end

  test "success? returns true on valid import" do
    service = AgendaImportService.new(valid_data).call
    assert service.success?
  end

  test "success? returns false on invalid import" do
    service = AgendaImportService.new("not a hash").call
    assert_not service.success?
  end

  test "handles missing keys in JSON" do
    service = AgendaImportService.new({}).call
    assert_not service.success?
    assert service.errors.any? { |e| e.include?("Invalid JSON structure") }
  end

  test "handles invalid structure" do
    service = AgendaImportService.new({ "meeting" => "bad", "sections" => "bad" }).call
    assert_not service.success?
    assert service.errors.any? { |e| e.include?("Invalid JSON structure") }
  end

  test "reports validation errors" do
    data = valid_data
    data["meeting"]["type"] = nil
    service = AgendaImportService.new(data).call
    assert_not service.success?
    assert service.errors.any?
  end

  test "duplicate date+type creates new version" do
    assert_no_difference "Meeting.count" do
      assert_difference "AgendaVersion.count", 1 do
        service = AgendaImportService.new(existing_meeting_data).call

        assert service.success?
        assert service.new_version?
        assert_equal 2, service.agenda_version.version_number
        assert_equal 12, service.agenda_version.agenda_pages
        assert_equal meetings(:regular_meeting), service.meeting
      end
    end
  end

  test "rolls back version on section failure" do
    initial_version_count = AgendaVersion.count
    initial_section_count = AgendaSection.count

    data = existing_meeting_data
    # Add a section with missing required fields to cause failure
    data["sections"] << { "number" => nil, "title" => nil, "type" => nil, "items" => [] }

    service = AgendaImportService.new(data).call

    assert_not service.success?
    assert_equal initial_version_count, AgendaVersion.count
    assert_equal initial_section_count, AgendaSection.count
  end

  test "handles empty sections" do
    data = valid_data
    data["sections"] = [
      { "number" => 1, "title" => "EMPTY SECTION", "type" => "adjournment", "items" => [] }
    ]

    service = AgendaImportService.new(data).call
    assert service.success?
    assert_equal 1, service.agenda_version.agenda_sections.count
    assert_equal 0, service.agenda_version.agenda_items.count
  end

  test "sets position correctly from array index" do
    service = AgendaImportService.new(valid_data).call
    assert service.success?

    ordinance_section = service.agenda_version.agenda_sections.find_by(section_type: "ordinance_first_reading")
    items = ordinance_section.agenda_items.order(:position)

    assert_equal 0, items.first.position
    assert_equal 1, items.second.position
  end
end
