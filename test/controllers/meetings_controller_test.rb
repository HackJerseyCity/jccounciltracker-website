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

  test "show with version param" do
    get meeting_path(meetings(:regular_meeting), version: 1)
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

  test "show defaults to latest published version when latest is draft" do
    meeting = meetings(:regular_meeting)
    v1 = agenda_versions(:regular_meeting_v1)
    v2 = AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    get meeting_path(meeting)
    assert_response :success
    assert_select "p", text: "9"  # v1's agenda_pages
  end

  test "show rejects version param for draft versions" do
    meeting = meetings(:regular_meeting)
    v2 = AgendaVersion.create!(meeting: meeting, version_number: 2, status: :draft)

    get meeting_path(meeting, version: 2)
    assert_response :success
    assert_select "p", text: "N/A"  # no version found, shows N/A for pages
  end
end
