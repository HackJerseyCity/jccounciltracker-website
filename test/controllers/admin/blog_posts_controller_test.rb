require "test_helper"

module Admin
  class BlogPostsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:content_admin)
      sign_in_as(@admin)
      @post = blog_posts(:published_post)
    end

    test "index requires admin" do
      sign_out
      sign_in_as(users(:regular_user))
      get admin_blog_posts_path
      assert_redirected_to root_path
    end

    test "index accessible to content admin" do
      get admin_blog_posts_path
      assert_response :success
    end

    test "index accessible to site admin" do
      sign_out
      sign_in_as(users(:site_admin))
      get admin_blog_posts_path
      assert_response :success
    end

    test "index lists all posts" do
      get admin_blog_posts_path
      assert_response :success
      assert_select "td", text: /Welcome to CouncilTracker/
      assert_select "td", text: /Upcoming Features/
    end

    test "show displays post" do
      get admin_blog_post_path(@post)
      assert_response :success
      assert_select "h1", text: @post.title
    end

    test "new renders form" do
      get new_admin_blog_post_path
      assert_response :success
      assert_select "form"
    end

    test "create with valid params" do
      assert_difference "BlogPost.count", 1 do
        post admin_blog_posts_path, params: {
          blog_post: { title: "New Post", body: "Post content here." }
        }
      end

      created = BlogPost.last
      assert_equal @admin, created.author
      assert created.draft?
      assert_redirected_to admin_blog_post_path(created)
    end

    test "create with invalid params re-renders form" do
      assert_no_difference "BlogPost.count" do
        post admin_blog_posts_path, params: {
          blog_post: { title: "", body: "" }
        }
      end
      assert_response :unprocessable_entity
    end

    test "edit renders form" do
      get edit_admin_blog_post_path(@post)
      assert_response :success
    end

    test "update with valid params" do
      patch admin_blog_post_path(@post), params: {
        blog_post: { title: "Updated Title" }
      }
      assert_redirected_to admin_blog_post_path(@post)
      assert_equal "Updated Title", @post.reload.title
    end

    test "update with invalid params re-renders form" do
      patch admin_blog_post_path(@post), params: {
        blog_post: { title: "" }
      }
      assert_response :unprocessable_entity
    end

    test "destroy deletes post" do
      assert_difference "BlogPost.count", -1 do
        delete admin_blog_post_path(@post)
      end
      assert_redirected_to admin_blog_posts_path
    end

    test "publish toggles published state" do
      draft = blog_posts(:draft_post)
      post publish_admin_blog_post_path(draft)
      assert draft.reload.published?
      assert_redirected_to admin_blog_post_path(draft)
    end

    test "unpublish toggles published state" do
      post publish_admin_blog_post_path(@post)
      assert @post.reload.draft?
      assert_redirected_to admin_blog_post_path(@post)
    end

    test "regular user cannot access admin blog" do
      sign_out
      sign_in_as(users(:regular_user))
      get admin_blog_posts_path
      assert_redirected_to root_path
    end
  end
end
