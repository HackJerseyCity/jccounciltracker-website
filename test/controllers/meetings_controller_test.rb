require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  test "index is publicly accessible" do
    get meetings_path
    assert_response :success
  end

  test "show is publicly accessible" do
    get meeting_path(meetings(:regular_meeting))
    assert_response :success
  end

  test "index works when authenticated" do
    sign_in_as(users(:regular_user))
    get meetings_path
    assert_response :success
  end

  test "show works when authenticated" do
    sign_in_as(users(:regular_user))
    get meeting_path(meetings(:regular_meeting))
    assert_response :success
  end
end
