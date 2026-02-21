require "test_helper"

class Admin::MeetingsControllerTest < ActionDispatch::IntegrationTest
  # --- index ---

  test "index as content_admin" do
    sign_in_as(users(:content_admin))
    get admin_meetings_path
    assert_response :success
  end

  test "index as site_admin" do
    sign_in_as(users(:site_admin))
    get admin_meetings_path
    assert_response :success
  end

  test "index as regular_user redirects" do
    sign_in_as(users(:regular_user))
    get admin_meetings_path
    assert_redirected_to root_path
  end

  test "index unauthenticated redirects to login" do
    get admin_meetings_path
    assert_redirected_to new_session_path
  end

  # --- show ---

  test "show as content_admin" do
    sign_in_as(users(:content_admin))
    get admin_meeting_path(meetings(:regular_meeting))
    assert_response :success
  end

  test "show as site_admin" do
    sign_in_as(users(:site_admin))
    get admin_meeting_path(meetings(:regular_meeting))
    assert_response :success
  end

  # --- new ---

  test "new as content_admin" do
    sign_in_as(users(:content_admin))
    get new_admin_meeting_path
    assert_response :success
  end

  # --- create ---

  test "create with valid JSON" do
    sign_in_as(users(:content_admin))

    json_data = {
      meeting: { type: "special", date: "2026-04-01" },
      agenda_pages: 3,
      sections: [
        { number: 1, title: "RESOLUTIONS", type: "resolutions", items: [
          { item_number: "1.1", title: "A test resolution", page_start: 1, page_end: 3,
            file_number: "Res. 26-100", item_type: "resolution", url: nil }
        ] }
      ]
    }.to_json

    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", false, original_filename: "test.json"
    )

    assert_difference "Meeting.count", 1 do
      post admin_meetings_path, params: { agenda_file: file }
    end

    meeting = Meeting.find_by(date: "2026-04-01", meeting_type: "special")
    assert_redirected_to admin_meeting_path(meeting)
    assert_equal 1, meeting.agenda_sections.count
    assert_equal 1, meeting.agenda_items.count
  end

  test "create without file" do
    sign_in_as(users(:content_admin))

    assert_no_difference "Meeting.count" do
      post admin_meetings_path
    end

    assert_response :unprocessable_entity
  end

  test "create with duplicate meeting" do
    sign_in_as(users(:content_admin))

    json_data = {
      meeting: { type: "regular", date: "2026-02-25" },
      agenda_pages: 9,
      sections: []
    }.to_json

    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", false, original_filename: "dup.json"
    )

    assert_no_difference "Meeting.count" do
      post admin_meetings_path, params: { agenda_file: file }
    end

    assert_response :unprocessable_entity
  end

  # --- destroy ---

  test "destroy as content_admin" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    assert_difference "Meeting.count", -1 do
      delete admin_meeting_path(meeting)
    end

    assert_redirected_to admin_meetings_path
  end
end
