require "test_helper"

class CouncilMemberTest < ActiveSupport::TestCase
  # --- validations ---

  test "valid with all required attributes" do
    member = CouncilMember.new(first_name: "Test", last_name: "Person", seat: :ward_a, term_start: Date.new(2025, 7, 1))
    assert member.valid?
  end

  test "validates presence of first_name" do
    member = CouncilMember.new(first_name: nil, last_name: "Person", seat: :ward_a, term_start: Date.current)
    assert_not member.valid?
    assert_includes member.errors[:first_name], "can't be blank"
  end

  test "validates presence of last_name" do
    member = CouncilMember.new(first_name: "Test", last_name: nil, seat: :ward_a, term_start: Date.current)
    assert_not member.valid?
    assert_includes member.errors[:last_name], "can't be blank"
  end

  test "validates presence of seat" do
    member = CouncilMember.new(first_name: "Test", last_name: "Person", seat: nil, term_start: Date.current)
    assert_not member.valid?
    assert_includes member.errors[:seat], "can't be blank"
  end

  test "validates presence of term_start" do
    member = CouncilMember.new(first_name: "Test", last_name: "Person", seat: :ward_a, term_start: nil)
    assert_not member.valid?
    assert_includes member.errors[:term_start], "can't be blank"
  end

  test "validates term_end after term_start" do
    member = CouncilMember.new(
      first_name: "Test", last_name: "Person", seat: :ward_a,
      term_start: Date.new(2025, 7, 1), term_end: Date.new(2025, 1, 1)
    )
    assert_not member.valid?
    assert_includes member.errors[:term_end], "must be after term start"
  end

  test "allows blank term_end" do
    member = CouncilMember.new(first_name: "Test", last_name: "Person", seat: :ward_a, term_start: Date.current, term_end: nil)
    assert member.valid?
  end

  # --- instance methods ---

  test "full_name returns first and last name" do
    assert_equal "Mira Ridley", council_members(:ridley).full_name
  end

  test "display_name returns full name with seat" do
    assert_equal "Mira Ridley (Ward A)", council_members(:ridley).display_name
  end

  test "seat_label returns Ward letter for ward seats" do
    assert_equal "Ward A", council_members(:ridley).seat_label
  end

  test "seat_label returns At Large for at_large seat" do
    assert_equal "At Large", council_members(:lavarro).seat_label
  end

  test "current? returns true for member with no term_end" do
    assert council_members(:ridley).current?
  end

  test "current? returns false for former member" do
    assert_not council_members(:former_member).current?
  end

  # --- scopes ---

  test "current scope includes members with no term_end" do
    assert_includes CouncilMember.current, council_members(:ridley)
    assert_includes CouncilMember.current, council_members(:lavarro)
  end

  test "current scope excludes past members" do
    assert_not_includes CouncilMember.current, council_members(:former_member)
  end

  test "alphabetical scope orders by last_name then first_name" do
    members = CouncilMember.alphabetical
    last_names = members.map(&:last_name)
    assert_equal last_names.sort, last_names
  end

  # --- enum ---

  test "seat enum predicates work" do
    assert council_members(:ridley).ward_a?
    assert council_members(:lavarro).at_large?
    assert council_members(:former_member).ward_b?
  end

  # --- votes association ---

  test "has_many votes" do
    assert_includes council_members(:ridley).votes, votes(:ridley_aye)
  end

  test "has_many voted_agenda_items through votes" do
    assert_includes council_members(:ridley).voted_agenda_items, agenda_items(:ordinance_with_details)
  end

  test "destroying council_member destroys associated votes" do
    member = council_members(:ridley)
    assert_difference "Vote.count", -member.votes.count do
      member.destroy
    end
  end
end
