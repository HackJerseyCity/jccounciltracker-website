require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    vote = Vote.new(
      agenda_item: agenda_items(:resolution_item),
      council_member: council_members(:ridley),
      position: :aye
    )
    assert vote.valid?
  end

  test "validates presence of position" do
    vote = Vote.new(
      agenda_item: agenda_items(:resolution_item),
      council_member: council_members(:ridley),
      position: nil
    )
    assert_not vote.valid?
    assert_includes vote.errors[:position], "can't be blank"
  end

  test "validates uniqueness of council_member per agenda_item" do
    existing = votes(:ridley_aye)
    duplicate = Vote.new(
      agenda_item: existing.agenda_item,
      council_member: existing.council_member,
      position: :nay
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:council_member_id], "has already been taken"
  end

  test "allows same council_member on different agenda_items" do
    vote = Vote.new(
      agenda_item: agenda_items(:resolution_item),
      council_member: council_members(:ridley),
      position: :aye
    )
    assert vote.valid?
  end

  test "enum predicates work" do
    assert votes(:ridley_aye).aye?
    assert votes(:lavarro_nay).nay?
  end

  test "belongs_to agenda_item" do
    assert_equal agenda_items(:ordinance_with_details), votes(:ridley_aye).agenda_item
  end

  test "belongs_to council_member" do
    assert_equal council_members(:ridley), votes(:ridley_aye).council_member
  end
end
