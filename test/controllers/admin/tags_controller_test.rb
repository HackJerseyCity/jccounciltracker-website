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

  test "search limits results to 10" do
    sign_in_as(users(:content_admin))
    15.times { |i| Tag.create!(name: "Test Tag #{i}") }

    get search_admin_tags_path(q: "Test Tag", format: :json)
    json = JSON.parse(response.body)
    assert_equal 10, json.size
  end
end
