require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  # --- auth ---

  test "search requires authentication" do
    get search_admin_tags_path(q: "bud")
    assert_redirected_to new_session_path
  end

  test "search requires admin" do
    sign_in_as(users(:regular_user))
    get search_admin_tags_path(q: "bud")
    assert_redirected_to root_path
  end

  # --- search ---

  test "search returns matching tags as JSON" do
    sign_in_as(users(:content_admin))
    get search_admin_tags_path(q: "bud", format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.size
    assert_equal "Budget", json.first["name"]
    assert json.first["id"].present?
  end

  test "search is case-insensitive" do
    sign_in_as(users(:content_admin))
    get search_admin_tags_path(q: "INFRA", format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.size
    assert_equal "Infrastructure", json.first["name"]
  end

  test "search returns empty array when no match" do
    sign_in_as(users(:content_admin))
    get search_admin_tags_path(q: "zzz", format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [], json
  end

  # --- index ---

  test "index requires authentication" do
    get admin_tags_path
    assert_redirected_to new_session_path
  end

  test "index shows all tags with item counts" do
    sign_in_as(users(:content_admin))
    get admin_tags_path
    assert_response :success
    assert_select "table"
  end

  test "index filters by search query" do
    sign_in_as(users(:content_admin))
    get admin_tags_path(q: "bud")
    assert_response :success
    assert_select "span.bg-indigo-100", text: "Budget"
  end

  # --- destroy ---

  test "destroy requires authentication" do
    assert_no_difference("Tag.count") do
      delete admin_tag_path(tags(:housing))
    end
    assert_redirected_to new_session_path
  end

  test "destroy deletes a tag" do
    sign_in_as(users(:content_admin))
    assert_difference("Tag.count", -1) do
      delete admin_tag_path(tags(:housing))
    end
    assert_redirected_to admin_tags_path
  end

  test "search limits results to 10" do
    sign_in_as(users(:content_admin))
    15.times { |i| Tag.create!(name: "Test Tag #{i}") }

    get search_admin_tags_path(q: "Test Tag", format: :json)
    json = JSON.parse(response.body)
    assert_equal 10, json.size
  end
end
