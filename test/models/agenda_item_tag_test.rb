require "test_helper"

class AgendaItemTagTest < ActiveSupport::TestCase
  test "validates uniqueness of tag scoped to agenda_item" do
    existing = agenda_item_tags(:ordinance_budget)
    duplicate = AgendaItemTag.new(
      agenda_item: existing.agenda_item,
      tag: existing.tag
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end

  test "belongs_to agenda_item" do
    ait = agenda_item_tags(:ordinance_budget)
    assert_equal agenda_items(:ordinance_with_details), ait.agenda_item
  end

  test "belongs_to tag" do
    ait = agenda_item_tags(:ordinance_budget)
    assert_equal tags(:budget), ait.tag
  end
end
