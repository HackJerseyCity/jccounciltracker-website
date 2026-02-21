require "test_helper"

class AgendaItemTest < ActiveSupport::TestCase
  test "validates presence of item_number" do
    item = AgendaItem.new(agenda_section: agenda_sections(:ordinance_first_reading), title: "Test", item_type: :ordinance, position: 0)
    assert_not item.valid?
    assert_includes item.errors[:item_number], "can't be blank"
  end

  test "validates presence of title" do
    item = AgendaItem.new(agenda_section: agenda_sections(:ordinance_first_reading), item_number: "99.1", item_type: :ordinance, position: 0)
    assert_not item.valid?
    assert_includes item.errors[:title], "can't be blank"
  end

  test "validates presence of item_type" do
    item = AgendaItem.new(agenda_section: agenda_sections(:ordinance_first_reading), item_number: "99.1", title: "Test", position: 0)
    assert_not item.valid?
    assert_includes item.errors[:item_type], "can't be blank"
  end

  test "validates uniqueness of item_number scoped to agenda_section" do
    existing = agenda_items(:ordinance_with_details)
    duplicate = AgendaItem.new(
      agenda_section: existing.agenda_section,
      item_number: existing.item_number,
      title: "Duplicate",
      item_type: :ordinance,
      position: 99
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:item_number], "has already been taken"
  end

  test "belongs_to agenda_section" do
    item = agenda_items(:ordinance_with_details)
    assert_equal agenda_sections(:ordinance_first_reading), item.agenda_section
  end

  test "has_one agenda_version through agenda_section" do
    item = agenda_items(:ordinance_with_details)
    assert_equal agenda_versions(:regular_meeting_v1), item.agenda_version
  end

  test "has_one meeting through agenda_version" do
    item = agenda_items(:ordinance_with_details)
    assert_equal meetings(:regular_meeting), item.meeting
  end

  test "nullable fields can be nil" do
    item = agenda_items(:item_with_nulls)
    assert_nil item.page_start
    assert_nil item.page_end
    assert_nil item.file_number
    assert_nil item.url
  end

  test "item_type enum provides predicates" do
    assert agenda_items(:ordinance_with_details).ordinance?
    assert agenda_items(:resolution_item).resolution?
    assert agenda_items(:item_with_nulls).other?
  end

  # --- votes association ---

  test "has_many votes" do
    item = agenda_items(:ordinance_with_details)
    assert_includes item.votes, votes(:ridley_aye)
    assert_includes item.votes, votes(:lavarro_nay)
  end

  test "destroying agenda_item destroys associated votes" do
    item = agenda_items(:ordinance_with_details)
    assert_difference "Vote.count", -item.votes.count do
      item.destroy
    end
  end

  # --- result validation ---

  test "allows nil result" do
    item = agenda_items(:ordinance_with_details)
    item.result = nil
    assert item.valid?
  end

  test "allows valid result values" do
    item = agenda_items(:ordinance_with_details)
    AgendaItem::VALID_RESULTS.each do |result|
      item.result = result
      assert item.valid?, "Expected '#{result}' to be valid"
    end
  end

  test "rejects invalid result values" do
    item = agenda_items(:ordinance_with_details)
    item.result = "invalid_result"
    assert_not item.valid?
    assert_includes item.errors[:result], "is not included in the list"
  end

  # --- voted_on scope ---

  test "voted_on scope returns items with a result" do
    item = agenda_items(:ordinance_with_details)
    item.update!(result: "approved")

    assert_includes AgendaItem.voted_on, item
    assert_not_includes AgendaItem.voted_on, agenda_items(:resolution_item)
  end
end
