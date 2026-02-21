require "test_helper"

class AgendaVersionTest < ActiveSupport::TestCase
  test "validates presence of version_number" do
    version = AgendaVersion.new(meeting: meetings(:regular_meeting))
    version.version_number = nil
    assert_not version.valid?
    assert_includes version.errors[:version_number], "can't be blank"
  end

  test "validates version_number is positive integer" do
    version = AgendaVersion.new(meeting: meetings(:regular_meeting), version_number: 0)
    assert_not version.valid?
    assert_includes version.errors[:version_number], "must be greater than 0"
  end

  test "validates uniqueness of version_number scoped to meeting" do
    existing = agenda_versions(:regular_meeting_v1)
    duplicate = AgendaVersion.new(
      meeting: existing.meeting,
      version_number: existing.version_number
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:version_number], "has already been taken"
  end

  test "belongs_to meeting" do
    version = agenda_versions(:regular_meeting_v1)
    assert_equal meetings(:regular_meeting), version.meeting
  end

  test "has_many agenda_sections" do
    version = agenda_versions(:regular_meeting_v1)
    assert_includes version.agenda_sections, agenda_sections(:ordinance_first_reading)
    assert_includes version.agenda_sections, agenda_sections(:resolutions)
  end

  test "has_many agenda_items through agenda_sections" do
    version = agenda_versions(:regular_meeting_v1)
    assert_includes version.agenda_items, agenda_items(:ordinance_with_details)
    assert_includes version.agenda_items, agenda_items(:resolution_item)
  end

  test "latest? returns true for highest version" do
    version = agenda_versions(:regular_meeting_v1)
    assert version.latest?
  end

  test "latest? returns false when newer version exists" do
    v1 = agenda_versions(:regular_meeting_v1)
    AgendaVersion.create!(meeting: v1.meeting, version_number: 2)
    assert_not v1.latest?
  end

  test "display_label includes version number and upload date" do
    version = agenda_versions(:regular_meeting_v1)
    label = version.display_label
    assert_match(/Version 1/, label)
    assert_match(/uploaded/, label)
    assert_match(/- Latest/, label)
  end

  test "cascade deletes agenda_sections and agenda_items" do
    version = agenda_versions(:regular_meeting_v1)
    section_ids = version.agenda_section_ids
    item_ids = version.agenda_item_ids

    assert section_ids.any?
    assert item_ids.any?

    version.destroy!

    assert_empty AgendaSection.where(id: section_ids)
    assert_empty AgendaItem.where(id: item_ids)
  end
end
