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

  test "has_many agenda_sections" do
    meeting = meetings(:regular_meeting)
    assert_includes meeting.agenda_sections, agenda_sections(:ordinance_first_reading)
    assert_includes meeting.agenda_sections, agenda_sections(:resolutions)
  end

  test "has_many agenda_items through agenda_sections" do
    meeting = meetings(:regular_meeting)
    assert_includes meeting.agenda_items, agenda_items(:ordinance_with_details)
    assert_includes meeting.agenda_items, agenda_items(:resolution_item)
  end

  test "cascade deletes agenda_sections and agenda_items" do
    meeting = meetings(:regular_meeting)
    section_ids = meeting.agenda_section_ids
    item_ids = meeting.agenda_item_ids

    assert section_ids.any?
    assert item_ids.any?

    meeting.destroy!

    assert_empty AgendaSection.where(id: section_ids)
    assert_empty AgendaItem.where(id: item_ids)
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
