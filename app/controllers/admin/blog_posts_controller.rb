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
      @blog_post.destroy!
      redirect_to admin_blog_posts_path, notice: "Blog post deleted."
    end

    def publish
      if @blog_post.published?
        @blog_post.unpublish!
        redirect_to admin_blog_post_path(@blog_post), notice: "Blog post unpublished."
      else
        @blog_post.publish!
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
