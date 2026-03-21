module Admin
  class TagsController < BaseController
    def index
      @tags = Tag.left_joins(:agenda_item_tags)
                  .select("tags.*, COUNT(agenda_item_tags.id) AS items_count")
                  .group("tags.id")
                  .order(Arel.sql("COUNT(agenda_item_tags.id) ASC, LOWER(tags.name) ASC"))

      @tags = @tags.search(params[:q]) if params[:q].present?
    end

    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params)
        redirect_to admin_tags_path(q: params[:q]), notice: "Tag renamed to \"#{@tag.name}\"."
      else
        redirect_to admin_tags_path(q: params[:q]), alert: @tag.errors.full_messages.to_sentence
      end
    end

    def destroy
      @tag = Tag.find(params[:id])
      @tag.destroy
      redirect_to admin_tags_path(q: params[:q]), notice: "Tag \"#{@tag.name}\" deleted."
    end

    def search
      tags = Tag.search(params[:q].to_s).alphabetical.limit(10)
      render json: tags.map { |t| { id: t.id, name: t.name } }
    end

    private

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
