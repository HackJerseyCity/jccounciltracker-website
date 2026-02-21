require "test_helper"

class TagTest < ActiveSupport::TestCase
  # --- validations ---

  test "validates presence of name" do
    tag = Tag.new(name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "validates uniqueness of name case-insensitively" do
    existing = tags(:budget)
    duplicate = Tag.new(name: existing.name.downcase)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # --- normalizes ---

  test "strips whitespace from name" do
    tag = Tag.new(name: "  Housing  ")
    assert_equal "Housing", tag.name
  end

  # --- scopes ---

  test "search scope finds tags by partial match" do
    results = Tag.search("bud")
    assert_includes results, tags(:budget)
    assert_not_includes results, tags(:housing)
  end

  test "search scope is case-insensitive" do
    results = Tag.search("BUDGET")
    assert_includes results, tags(:budget)
  end

  test "alphabetical scope orders by name" do
    ordered = Tag.alphabetical
    names = ordered.map(&:name)
    assert_equal names.sort_by(&:downcase), names
  end

  # --- associations ---

  test "has_many agenda_item_tags" do
    tag = tags(:budget)
    assert_includes tag.agenda_item_tags, agenda_item_tags(:ordinance_budget)
  end

  test "has_many agenda_items through agenda_item_tags" do
    tag = tags(:budget)
    assert_includes tag.agenda_items, agenda_items(:ordinance_with_details)
  end

  test "destroying tag destroys associated agenda_item_tags" do
    tag = tags(:budget)
    assert_difference "AgendaItemTag.count", -1 do
      tag.destroy
    end
  end
end
