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

  test "show with version param" do
    sign_in_as(users(:content_admin))
    get admin_meeting_path(meetings(:regular_meeting), version: 1)
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

    assert_difference [ "Meeting.count", "AgendaVersion.count" ], 1 do
      post admin_meetings_path, params: { agenda_file: file }
    end

    meeting = Meeting.find_by(date: "2026-04-01", meeting_type: "special")
    assert_redirected_to admin_meeting_path(meeting)
    assert_equal "Meeting agenda imported successfully.", flash[:notice]
    assert_equal 1, meeting.current_version.agenda_sections.count
    assert_equal 1, meeting.current_version.agenda_items.count
  end

  test "create without file" do
    sign_in_as(users(:content_admin))

    assert_no_difference "Meeting.count" do
      post admin_meetings_path
    end

    assert_response :unprocessable_entity
  end

  test "create with duplicate meeting creates new version" do
    sign_in_as(users(:content_admin))

    json_data = {
      meeting: { type: "regular", date: "2026-02-25" },
      agenda_pages: 12,
      sections: [
        { number: 1, title: "UPDATED SECTION", type: "regular_meeting", items: [] }
      ]
    }.to_json

    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", false, original_filename: "dup.json"
    )

    assert_no_difference "Meeting.count" do
      assert_difference "AgendaVersion.count", 1 do
        post admin_meetings_path, params: { agenda_file: file }
      end
    end

    meeting = meetings(:regular_meeting)
    assert_redirected_to admin_meeting_path(meeting)
    assert_match(/New version/, flash[:notice])
  end

  # --- import_minutes ---

  test "import_minutes with valid JSON" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    json_data = {
      meeting: { type: "regular", date: "2026-02-25" },
      council_members: [ "Ridley" ],
      items: [
        {
          item_number: "10.1",
          result: "approved",
          vote_tally: "9-0",
          votes: { Ridley: "aye" }
        }
      ]
    }.to_json

    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", false, original_filename: "minutes.json"
    )

    assert_difference "Vote.count", 1 do
      post import_minutes_admin_meeting_path(meeting), params: { minutes_file: file }
    end

    assert_redirected_to admin_meeting_path(meeting)
    assert_match(/Minutes imported successfully/, flash[:notice])

    item = agenda_items(:resolution_item).reload
    assert_equal "approved", item.result
    assert_equal "9-0", item.vote_tally
  end

  test "import_minutes without file" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    post import_minutes_admin_meeting_path(meeting)
    assert_redirected_to admin_meeting_path(meeting)
    assert_equal "Please select a JSON file to upload.", flash[:alert]
  end

  test "import_minutes with invalid JSON" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    file = Rack::Test::UploadedFile.new(
      StringIO.new("not json"), "application/json", false, original_filename: "bad.json"
    )

    post import_minutes_admin_meeting_path(meeting), params: { minutes_file: file }
    assert_redirected_to admin_meeting_path(meeting)
    assert_equal "Invalid JSON file.", flash[:alert]
  end

  test "import_minutes with missing meeting returns error" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    json_data = {
      meeting: { type: "special", date: "2099-01-01" },
      council_members: [],
      items: []
    }.to_json

    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", false, original_filename: "minutes.json"
    )

    post import_minutes_admin_meeting_path(meeting), params: { minutes_file: file }
    assert_redirected_to admin_meeting_path(meeting)
    assert_match(/No meeting found/, flash[:alert])
  end

  # --- delete_minutes ---

  test "delete_minutes removes votes and clears results" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)

    # Fixture votes exist on ordinance_with_details
    assert meeting.minutes_imported?

    delete delete_minutes_admin_meeting_path(meeting)

    assert_redirected_to admin_meeting_path(meeting)
    assert_equal "Minutes data deleted.", flash[:notice]

    item = agenda_items(:ordinance_with_details).reload
    assert_nil item.result
    assert_nil item.vote_tally
    assert_equal 0, item.votes.count

    assert_not meeting.reload.minutes_imported?
  end

  # --- publish ---

  test "publish toggles draft to published" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)
    version = agenda_versions(:regular_meeting_v1)
    version.update!(status: :draft)

    post publish_admin_meeting_path(meeting), params: { version_id: version.id }

    assert_redirected_to admin_meeting_path(meeting)
    assert version.reload.published?
    assert_match(/published/, flash[:notice])
  end

  test "publish toggles published to draft" do
    sign_in_as(users(:content_admin))
    meeting = meetings(:regular_meeting)
    version = agenda_versions(:regular_meeting_v1)
    assert version.published?

    post publish_admin_meeting_path(meeting), params: { version_id: version.id }

    assert_redirected_to admin_meeting_path(meeting)
    assert version.reload.draft?
    assert_match(/unpublished/, flash[:notice])
  end

  test "publish requires authentication" do
    meeting = meetings(:regular_meeting)
    version = agenda_versions(:regular_meeting_v1)

    post publish_admin_meeting_path(meeting), params: { version_id: version.id }
    assert_redirected_to new_session_path
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
