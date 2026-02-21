module Admin
  class AgendaItemTagsController < BaseController
    before_action :set_agenda_item

    def create
      tag = Tag.find_or_create_by!(name: params[:tag_name].to_s.strip)
      @agenda_item.agenda_item_tags.find_or_create_by!(tag: tag)

      render_tags_stream
    end

    def destroy
      agenda_item_tag = @agenda_item.agenda_item_tags.find(params[:id])
      agenda_item_tag.destroy!

      render_tags_stream
    end

    private

    def set_agenda_item
      @agenda_item = AgendaItem.find(params[:agenda_item_id])
    end

    def render_tags_stream
      @agenda_item.reload
      render turbo_stream: turbo_stream.replace(
        "agenda_item_#{@agenda_item.id}_tags",
        partial: "admin/agenda_item_tags/tags",
        locals: { agenda_item: @agenda_item }
      )
    end
  end
end
