require "test_helper"

class Admin::AgendaItemsControllerTest < ActionDispatch::IntegrationTest
  test "untagged page as content_admin" do
    sign_in_as(users(:content_admin))
    get untagged_admin_agenda_items_path
    assert_response :success
  end

  test "untagged page with type filter" do
    sign_in_as(users(:content_admin))
    get untagged_admin_agenda_items_path(type: "ordinance")
    assert_response :success
  end

  test "untagged page with meeting filter" do
    sign_in_as(users(:content_admin))
    get untagged_admin_agenda_items_path(meeting_id: meetings(:regular_meeting).id)
    assert_response :success
  end

  test "untagged page requires authentication" do
    get untagged_admin_agenda_items_path
    assert_redirected_to new_session_path
  end

  test "auto_tag_all as content_admin" do
    sign_in_as(users(:content_admin))
    post auto_tag_all_admin_agenda_items_path
    assert_redirected_to untagged_admin_agenda_items_path
    assert_match(/Auto-tagged/, flash[:notice])
  end
end
