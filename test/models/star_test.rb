require "test_helper"

class StarTest < ActiveSupport::TestCase
  test "valid star" do
    star = Star.new(user: users(:regular_user), starrable: meetings(:regular_meeting))
    assert star.valid?
  end

  test "requires user" do
    star = Star.new(starrable: meetings(:regular_meeting))
    assert_not star.valid?
  end

  test "requires starrable" do
    star = Star.new(user: users(:regular_user))
    assert_not star.valid?
  end

  test "unique per user and starrable" do
    Star.create!(user: users(:regular_user), starrable: meetings(:regular_meeting))
    duplicate = Star.new(user: users(:regular_user), starrable: meetings(:regular_meeting))
    assert_not duplicate.valid?
  end

  test "different users can star the same item" do
    Star.create!(user: users(:regular_user), starrable: meetings(:regular_meeting))
    star = Star.new(user: users(:content_admin), starrable: meetings(:regular_meeting))
    assert star.valid?
  end

  test "user can star different types" do
    Star.create!(user: users(:regular_user), starrable: meetings(:regular_meeting))
    star = Star.new(user: users(:regular_user), starrable: tags(:budget))
    assert star.valid?
  end

  test "destroying starrable destroys stars" do
    tag = Tag.create!(name: "Temporary")
    Star.create!(user: users(:regular_user), starrable: tag)
    assert_difference "Star.count", -1 do
      tag.destroy
    end
  end

  test "destroying user destroys stars" do
    user = User.create!(name: "Temp", email_address: "temp@example.com", password: "password")
    Star.create!(user: user, starrable: tags(:budget))
    assert_difference "Star.count", -1 do
      user.destroy
    end
  end

  test "user starred? helper" do
    user = users(:regular_user)
    meeting = meetings(:regular_meeting)
    assert_not user.starred?(meeting)

    Star.create!(user: user, starrable: meeting)
    assert user.starred?(meeting)
  end
end
