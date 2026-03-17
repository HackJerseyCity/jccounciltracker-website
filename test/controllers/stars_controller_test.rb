require "test_helper"

class StarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular_user)
    sign_in_as(@user)
  end

  test "index requires authentication" do
    sign_out
    get stars_path
    assert_redirected_to new_session_path
  end

  test "index shows empty state" do
    get stars_path
    assert_response :success
    assert_select "p", text: /haven't starred/
  end

  test "index shows starred items grouped by type" do
    Star.create!(user: @user, starrable: meetings(:regular_meeting))
    Star.create!(user: @user, starrable: tags(:budget))

    get stars_path
    assert_response :success
    assert_select "h2", text: "Meetings"
    assert_select "h2", text: "Topics"
  end

  test "create stars a meeting" do
    meeting = meetings(:regular_meeting)
    assert_difference "Star.count", 1 do
      post stars_path, params: { starrable_type: "Meeting", starrable_id: meeting.id }
    end
    assert @user.starred?(meeting)
  end

  test "create is idempotent" do
    meeting = meetings(:regular_meeting)
    Star.create!(user: @user, starrable: meeting)
    assert_no_difference "Star.count" do
      post stars_path, params: { starrable_type: "Meeting", starrable_id: meeting.id }
    end
  end

  test "create rejects invalid starrable type" do
    post stars_path, params: { starrable_type: "User", starrable_id: @user.id }
    assert_response :unprocessable_entity
  end

  test "create requires authentication" do
    sign_out
    post stars_path, params: { starrable_type: "Meeting", starrable_id: meetings(:regular_meeting).id }
    assert_redirected_to new_session_path
  end

  test "destroy removes star" do
    star = Star.create!(user: @user, starrable: meetings(:regular_meeting))
    assert_difference "Star.count", -1 do
      delete star_path(star)
    end
  end

  test "destroy requires authentication" do
    star = Star.create!(user: @user, starrable: meetings(:regular_meeting))
    sign_out
    delete star_path(star)
    assert_redirected_to new_session_path
  end

  test "create with turbo stream" do
    meeting = meetings(:regular_meeting)
    post stars_path, params: { starrable_type: "Meeting", starrable_id: meeting.id }, as: :turbo_stream
    assert_response :success
  end

  test "destroy with turbo stream" do
    star = Star.create!(user: @user, starrable: meetings(:regular_meeting))
    delete star_path(star), as: :turbo_stream
    assert_response :success
  end
end
