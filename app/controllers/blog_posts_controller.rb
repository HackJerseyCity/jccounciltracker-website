class BlogPostsController < ApplicationController
  allow_unauthenticated_access
  layout :choose_layout

  def index
    @blog_posts = BlogPost.published.includes(:user, :rich_text_body)
  end

  def show
    @blog_post = BlogPost.published.find_by!(slug: params[:id])
  end

  private

  def choose_layout
    action_name == "show" ? "blog_post" : "dashboard"
  end
end
