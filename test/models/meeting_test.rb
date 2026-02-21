require "test_helper"

class MeetingTest < ActiveSupport::TestCase
  test "validates presence of date" do
    meeting = Meeting.new(meeting_type: :regular)
    assert_not meeting.valid?
    assert_includes meeting.errors[:date], "can't be blank"
  end

  test "validates presence of meeting_type" do
    meeting = Meeting.new(date: Date.new(2026, 3, 1))
    assert_not meeting.valid?
    assert_includes meeting.errors[:meeting_type], "can't be blank"
  end

  test "validates uniqueness of date scoped to meeting_type" do
    existing = meetings(:regular_meeting)
    duplicate = Meeting.new(date: existing.date, meeting_type: existing.meeting_type)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:date], "has already been taken"
  end

  test "allows same date with different meeting_type" do
    existing = meetings(:regular_meeting)
    different_type = Meeting.new(date: existing.date, meeting_type: :special)
    assert different_type.valid?
  end

  test "has_many agenda_versions" do
    meeting = meetings(:regular_meeting)
    assert_includes meeting.agenda_versions, agenda_versions(:regular_meeting_v1)
  end

  test "current_version returns latest version" do
    meeting = meetings(:regular_meeting)
    assert_equal agenda_versions(:regular_meeting_v1), meeting.current_version
  end

  test "version finds specific version by number" do
    meeting = meetings(:regular_meeting)
    assert_equal agenda_versions(:regular_meeting_v1), meeting.version(1)
    assert_nil meeting.version(99)
  end

  test "agenda_sections delegates through current_version" do
    meeting = meetings(:regular_meeting)
    assert_includes meeting.agenda_sections, agenda_sections(:ordinance_first_reading)
    assert_includes meeting.agenda_sections, agenda_sections(:resolutions)
  end

  test "agenda_items delegates through current_version" do
    meeting = meetings(:regular_meeting)
    assert_includes meeting.agenda_items, agenda_items(:ordinance_with_details)
    assert_includes meeting.agenda_items, agenda_items(:resolution_item)
  end

  test "agenda_pages delegates through current_version" do
    meeting = meetings(:regular_meeting)
    assert_equal 9, meeting.agenda_pages
  end

  test "versions_count returns number of versions" do
    meeting = meetings(:regular_meeting)
    assert_equal 1, meeting.versions_count
  end

  test "cascade deletes through versions" do
    meeting = meetings(:regular_meeting)
    version_ids = meeting.agenda_version_ids
    section_ids = meeting.current_version.agenda_section_ids
    item_ids = meeting.current_version.agenda_item_ids

    assert version_ids.any?
    assert section_ids.any?
    assert item_ids.any?

    meeting.destroy!

    assert_empty AgendaVersion.where(id: version_ids)
    assert_empty AgendaSection.where(id: section_ids)
    assert_empty AgendaItem.where(id: item_ids)
  end

  test "current_published_version returns latest published version" do
    meeting = meetings(:regular_meeting)
    v1 = agenda_versions(:regular_meeting_v1)
    v2 = AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    assert_equal v1, meeting.current_published_version
  end

  test "current_published_version returns nil when all draft" do
    meeting = meetings(:regular_meeting)
    agenda_versions(:regular_meeting_v1).unpublish!

    assert_nil meeting.current_published_version
  end

  test "agenda_sections delegates through published version" do
    meeting = meetings(:regular_meeting)
    v2 = AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    assert_includes meeting.agenda_sections, agenda_sections(:ordinance_first_reading)
    assert_includes meeting.agenda_sections, agenda_sections(:resolutions)
  end

  test "agenda_items delegates through published version" do
    meeting = meetings(:regular_meeting)
    v2 = AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    assert_includes meeting.agenda_items, agenda_items(:ordinance_with_details)
  end

  test "published_versions_count only counts published" do
    meeting = meetings(:regular_meeting)
    AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    assert_equal 1, meeting.published_versions_count
  end

  test "chronological scope orders by date desc" do
    older = Meeting.create!(date: Date.new(2026, 1, 1), meeting_type: :special)
    meetings = Meeting.chronological
    assert_equal meetings(:regular_meeting), meetings.first
    assert_equal older, meetings.last
  end

  test "display_name returns formatted string" do
    meeting = meetings(:regular_meeting)
    assert_equal "Regular Meeting - February 25, 2026", meeting.display_name
  end
end
