require "test_helper"

class AutoTaggingServiceTest < ActiveSupport::TestCase
  # Fixtures provide: tags (budget, infrastructure, housing, parking, environmental, cannabis, grants)
  # and tag_rules for each of those tags.

  test "tags item matching a keyword rule" do
    item = agenda_items(:ordinance_with_details)
    item.update!(title: "An Ordinance supplementing Chapter 332 (Vehicles and Traffic) Article IX (Parking for the Disabled)")

    AutoTaggingService.new(item).call

    tag_names = item.tags.reload.pluck(:name).map(&:downcase)
    assert_includes tag_names, "parking"
  end

  test "tags item matching a phrase rule" do
    item = agenda_items(:resolution_item)
    item.update!(title: "A Resolution awarding Community Development Block Grant funds")

    AutoTaggingService.new(item).call

    tag_names = item.tags.reload.pluck(:name).map(&:downcase)
    assert_includes tag_names, "grants"
  end

  test "keyword rule uses word boundaries" do
    item = agenda_items(:resolution_item)
    # "parking" should not match "parks" tag (no parks rule in fixtures, but test word boundary)
    item.update!(title: "A discussion about Rochelle Park, NJ")

    AutoTaggingService.new(item).call

    tag_names = item.tags.reload.pluck(:name).map(&:downcase)
    # "parking" keyword rule should NOT match "Park"
    refute_includes tag_names, "parking"
  end

  test "is idempotent" do
    item = agenda_items(:resolution_item)
    item.update!(title: "Resolution providing local support for cannabis business")

    AutoTaggingService.new(item).call
    count_after_first = item.agenda_item_tags.reload.count

    AutoTaggingService.new(item).call
    count_after_second = item.agenda_item_tags.reload.count

    assert_equal count_after_first, count_after_second
    assert count_after_first > 0
  end

  test "leaves unmatched items untagged" do
    item = agenda_items(:item_with_nulls)
    item.update!(title: "A simple agenda item with no optional fields")

    AutoTaggingService.new(item).call

    assert_equal 0, item.tags.reload.count
  end

  test "applies multiple tags to one item" do
    item = agenda_items(:ordinance_with_details)
    item.update!(title: "An Ordinance about budget appropriations")

    AutoTaggingService.new(item).call

    tag_names = item.tags.reload.pluck(:name).map(&:downcase)
    assert_includes tag_names, "budget"
  end

  test "reuses existing tags" do
    existing_tag = tags(:cannabis)

    item = agenda_items(:resolution_item)
    item.update!(title: "Resolution providing local support for cannabis business")

    AutoTaggingService.new(item).call

    assert_includes item.tags.reload, existing_tag
  end

  test "tags multiple items at once" do
    item1 = agenda_items(:ordinance_with_details)
    item1.update!(title: "An Ordinance about parking")

    item2 = agenda_items(:resolution_item)
    item2.update!(title: "A Resolution about affordable housing trust funds")

    AutoTaggingService.new([ item1, item2 ]).call

    assert_includes item1.tags.reload.pluck(:name).map(&:downcase), "parking"
    assert_includes item2.tags.reload.pluck(:name).map(&:downcase), "housing"
  end

  test "environmental patterns match chromate and soil remediation" do
    item = agenda_items(:resolution_item)
    item.update!(title: "Letter re: Soil Remedial Action Permit Application, Hudson County Chromate 67")

    AutoTaggingService.new(item).call

    tag_names = item.tags.reload.pluck(:name).map(&:downcase)
    assert_includes tag_names, "environmental"
  end

  test "seed_default_rules creates rules for tags without rules" do
    # Remove all existing rules
    TagRule.delete_all

    AutoTaggingService.seed_default_rules!

    assert TagRule.count > 0
    assert Tag.where("LOWER(name) = ?", "parking").first.tag_rules.any?
    assert Tag.where("LOWER(name) = ?", "cannabis").first.tag_rules.any?
  end

  test "seed_default_rules does not duplicate existing rules" do
    AutoTaggingService.seed_default_rules!
    count_first = TagRule.count

    AutoTaggingService.seed_default_rules!
    count_second = TagRule.count

    assert_equal count_first, count_second
  end

  test "no rules means no tags applied" do
    TagRule.delete_all

    item = agenda_items(:item_with_nulls)
    item.update!(title: "An Ordinance about parking")

    AutoTaggingService.new(item).call

    assert_equal 0, item.tags.reload.count
  end
end
