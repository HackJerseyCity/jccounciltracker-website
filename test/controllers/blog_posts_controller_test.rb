require "test_helper"

class BlogPostsControllerTest < ActionDispatch::IntegrationTest
  test "index is publicly accessible" do
    get blog_posts_path
    assert_response :success
  end

  test "index shows published posts" do
    get blog_posts_path
    assert_response :success
    assert_select "h2", text: blog_posts(:published_post).title
  end

  test "index does not show draft posts" do
    get blog_posts_path
    assert_select "h2", text: blog_posts(:draft_post).title, count: 0
  end

  test "show displays published post" do
    get blog_post_path(blog_posts(:published_post))
    assert_response :success
    assert_select "h1", text: blog_posts(:published_post).title
  end

  test "show returns 404 for draft post" do
    get blog_post_path(blog_posts(:draft_post))
    assert_response :not_found
  end
end
