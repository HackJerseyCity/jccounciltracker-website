module Admin
  class TagsController < BaseController
    def index
      @tags = Tag.left_joins(:agenda_item_tags)
                  .select("tags.*, COUNT(agenda_item_tags.id) AS items_count")
                  .group("tags.id")
                  .order(Arel.sql("COUNT(agenda_item_tags.id) ASC, LOWER(tags.name) ASC"))

      @tags = @tags.search(params[:q]) if params[:q].present?
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
  end
end
