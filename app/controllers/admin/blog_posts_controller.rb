module Admin
  class BlogPostsController < BaseController
    before_action :set_blog_post, only: %i[show edit update destroy publish]

    def index
      @blog_posts = BlogPost.includes(:user).chronological
    end

    def show
    end

    def new
      @blog_post = BlogPost.new
    end

    def create
      @blog_post = BlogPost.new(blog_post_params)
      @blog_post.user = Current.user

      if @blog_post.save
        audit("blog_post.create", target: @blog_post)
        redirect_to admin_blog_post_path(@blog_post), notice: "Blog post created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @blog_post.update(blog_post_params)
        redirect_to admin_blog_post_path(@blog_post), notice: "Blog post updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      audit("blog_post.destroy", target: @blog_post, metadata: { title: @blog_post.title })
      @blog_post.destroy!
      redirect_to admin_blog_posts_path, notice: "Blog post deleted."
    end

    def publish
      if @blog_post.published?
        @blog_post.unpublish!
        audit("blog_post.unpublish", target: @blog_post)
        redirect_to admin_blog_post_path(@blog_post), notice: "Blog post unpublished."
      else
        @blog_post.publish!
        audit("blog_post.publish", target: @blog_post)
        redirect_to admin_blog_post_path(@blog_post), notice: "Blog post published."
      end
    end

    private

    def set_blog_post
      @blog_post = BlogPost.find_by!(slug: params[:id])
    end

    def blog_post_params
      params.expect(blog_post: [ :title, :slug, :body ])
    end
  end
end
