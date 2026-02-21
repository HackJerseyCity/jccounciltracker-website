require "test_helper"

class Admin::AgendaItemTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:content_admin))
    @agenda_item = agenda_items(:resolution_item)
  end

  # --- auth ---

  test "create requires authentication" do
    sign_out
    post admin_agenda_item_tags_path, params: { agenda_item_id: @agenda_item.id, tag_name: "Budget" }
    assert_redirected_to new_session_path
  end

  test "create requires admin" do
    sign_out
    sign_in_as(users(:regular_user))
    post admin_agenda_item_tags_path, params: { agenda_item_id: @agenda_item.id, tag_name: "Budget" }
    assert_redirected_to root_path
  end

  # --- create ---

  test "create with existing tag" do
    assert_no_difference "Tag.count" do
      assert_difference "AgendaItemTag.count", 1 do
        post admin_agenda_item_tags_path,
          params: { agenda_item_id: @agenda_item.id, tag_name: "Budget" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end

    assert_response :success
    assert @agenda_item.tags.include?(tags(:budget))
  end

  test "create with new tag" do
    assert_difference [ "Tag.count", "AgendaItemTag.count" ], 1 do
      post admin_agenda_item_tags_path,
        params: { agenda_item_id: @agenda_item.id, tag_name: "Environment" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "Environment", @agenda_item.reload.tags.last.name
  end

  test "create is idempotent" do
    post admin_agenda_item_tags_path,
      params: { agenda_item_id: @agenda_item.id, tag_name: "Budget" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_no_difference [ "Tag.count", "AgendaItemTag.count" ] do
      post admin_agenda_item_tags_path,
        params: { agenda_item_id: @agenda_item.id, tag_name: "Budget" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
  end

  # --- destroy ---

  test "destroy removes the agenda_item_tag" do
    ait = agenda_item_tags(:ordinance_budget)

    assert_difference "AgendaItemTag.count", -1 do
      delete admin_agenda_item_tag_path(ait),
        params: { agenda_item_id: ait.agenda_item_id },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
  end

  test "destroy requires authentication" do
    sign_out
    ait = agenda_item_tags(:ordinance_budget)
    delete admin_agenda_item_tag_path(ait), params: { agenda_item_id: ait.agenda_item_id }
    assert_redirected_to new_session_path
  end
end
