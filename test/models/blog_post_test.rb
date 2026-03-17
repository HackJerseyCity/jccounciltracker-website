require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  test "valid blog post" do
    post = BlogPost.new(title: "Test Post", body: "Some content", user: users(:content_admin))
    assert post.valid?
    assert post.slug.present?
  end

  test "requires title" do
    post = BlogPost.new(body: "Content", user: users(:content_admin))
    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "requires body" do
    post = BlogPost.new(title: "Title", user: users(:content_admin))
    assert_not post.valid?
    assert post.errors[:body].any?
  end

  test "requires user" do
    post = BlogPost.new(title: "Title", body: "Content")
    assert_not post.valid?
  end

  test "auto-generates slug from title" do
    post = BlogPost.new(title: "My Great Post!", body: "Content", user: users(:content_admin))
    post.valid?
    assert_equal "my-great-post", post.slug
  end

  test "slug uniqueness" do
    BlogPost.create!(title: "Test", slug: "test-slug", body: "Content", user: users(:content_admin))
    post = BlogPost.new(title: "Test", slug: "test-slug", body: "Content", user: users(:content_admin))
    assert_not post.valid?
    assert post.errors[:slug].any?
  end

  test "auto-generated slug avoids duplicates" do
    BlogPost.create!(title: "Test", body: "Content", user: users(:content_admin))
    post = BlogPost.create!(title: "Test", body: "Content 2", user: users(:content_admin))
    assert_equal "test-1", post.slug
  end

  test "slug format validation" do
    post = BlogPost.new(title: "Test", slug: "Invalid Slug!", body: "Content", user: users(:content_admin))
    assert_not post.valid?
    assert post.errors[:slug].any?
  end

  test "published scope" do
    published = BlogPost.published
    assert_includes published, blog_posts(:published_post)
    assert_not_includes published, blog_posts(:draft_post)
  end

  test "draft scope" do
    drafts = BlogPost.draft
    assert_includes drafts, blog_posts(:draft_post)
    assert_not_includes drafts, blog_posts(:published_post)
  end

  test "published?" do
    assert blog_posts(:published_post).published?
    assert_not blog_posts(:draft_post).published?
  end

  test "publish! sets published_at" do
    post = blog_posts(:draft_post)
    post.publish!
    assert post.published?
  end

  test "unpublish! clears published_at" do
    post = blog_posts(:published_post)
    post.unpublish!
    assert post.draft?
  end

  test "to_param returns slug" do
    assert_equal "welcome-to-counciltracker", blog_posts(:published_post).to_param
  end
end
