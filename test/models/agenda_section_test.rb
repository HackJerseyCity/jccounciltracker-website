require "test_helper"

class AgendaSectionTest < ActiveSupport::TestCase
  test "validates presence of number" do
    section = AgendaSection.new(meeting: meetings(:regular_meeting), title: "Test", section_type: :resolutions)
    assert_not section.valid?
    assert_includes section.errors[:number], "can't be blank"
  end

  test "validates presence of title" do
    section = AgendaSection.new(meeting: meetings(:regular_meeting), number: 99, section_type: :resolutions)
    assert_not section.valid?
    assert_includes section.errors[:title], "can't be blank"
  end

  test "validates presence of section_type" do
    section = AgendaSection.new(meeting: meetings(:regular_meeting), number: 99, title: "Test")
    assert_not section.valid?
    assert_includes section.errors[:section_type], "can't be blank"
  end

  test "validates uniqueness of number scoped to meeting" do
    existing = agenda_sections(:ordinance_first_reading)
    duplicate = AgendaSection.new(
      meeting: existing.meeting,
      number: existing.number,
      title: "Duplicate",
      section_type: :resolutions
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:number], "has already been taken"
  end

  test "belongs_to meeting" do
    section = agenda_sections(:ordinance_first_reading)
    assert_equal meetings(:regular_meeting), section.meeting
  end

  test "has_many agenda_items ordered by position" do
    section = agenda_sections(:ordinance_first_reading)
    assert_includes section.agenda_items, agenda_items(:ordinance_with_details)
  end

  test "section_type enum provides predicates" do
    section = agenda_sections(:ordinance_first_reading)
    assert section.ordinance_first_reading?
    assert_not section.resolutions?
  end
end
