module Admin
  class TagsController < BaseController
    SORT_COLUMNS = {
      "name" => "LOWER(tags.name)",
      "items" => "COUNT(agenda_item_tags.id)"
    }.freeze

    def index
      @tags = Tag.left_joins(:agenda_item_tags)
                  .select("tags.*, COUNT(agenda_item_tags.id) AS items_count")
                  .group("tags.id")

      sort_col = SORT_COLUMNS[params[:sort]] || SORT_COLUMNS["items"]
      direction = params[:direction] == "desc" ? "DESC" : "ASC"
      @tags = @tags.order(Arel.sql("#{sort_col} #{direction}, LOWER(tags.name) ASC"))

      @tags = @tags.search(params[:q]) if params[:q].present?
    end

    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params)
        @tag = Tag.left_joins(:agenda_item_tags)
                   .select("tags.*, COUNT(agenda_item_tags.id) AS items_count")
                   .where(id: @tag.id)
                   .group("tags.id")
                   .first
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_tags_path(q: params[:q]), notice: "Tag renamed to \"#{@tag.name}\"." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace(@tag, partial: "admin/tags/tag_error", locals: { tag: @tag }) }
          format.html { redirect_to admin_tags_path(q: params[:q]), alert: @tag.errors.full_messages.to_sentence }
        end
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
