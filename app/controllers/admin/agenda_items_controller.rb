module Admin
  class AgendaItemsController < BaseController
    def untagged
      scope = AgendaItem.left_joins(:agenda_item_tags)
                .where(agenda_item_tags: { id: nil })
                .includes(:tags, agenda_section: { agenda_version: :meeting })

      if params[:type].present? && AgendaItem.item_types.key?(params[:type])
        scope = scope.where(item_type: params[:type])
      end

      if params[:meeting_id].present?
        scope = scope.joins(agenda_section: :agenda_version)
                  .where(agenda_versions: { meeting_id: params[:meeting_id] })
      end

      @items = scope.order("meetings.date DESC, agenda_items.item_number ASC")
                 .references(:meetings)

      @untagged_count = @items.size
      @total_count = AgendaItem.count

      @meetings_for_filter = Meeting.joins(agenda_versions: { agenda_sections: :agenda_items })
                               .joins("LEFT JOIN agenda_item_tags ON agenda_item_tags.agenda_item_id = agenda_items.id")
                               .where(agenda_item_tags: { id: nil })
                               .distinct
                               .chronological
    end

    def auto_tag_all
      items = AgendaItem.left_joins(:agenda_item_tags)
                .where(agenda_item_tags: { id: nil })
                .to_a

      AutoTaggingService.new(items).call

      still_untagged = AgendaItem.left_joins(:agenda_item_tags)
                         .where(agenda_item_tags: { id: nil })
                         .count
      tagged_now = items.size - still_untagged

      redirect_to untagged_admin_agenda_items_path,
        notice: "Auto-tagged #{tagged_now} items. #{still_untagged} still need manual tagging."
    end

    def update
      @agenda_item = AgendaItem.find(params[:id])
      if @agenda_item.update(agenda_item_params)
        render turbo_stream: [
          turbo_stream.replace(
            "agenda_item_#{@agenda_item.id}_title",
            partial: "admin/agenda_items/title",
            locals: { item: @agenda_item }
          ),
          turbo_stream.replace(
            "agenda_item_#{@agenda_item.id}_title_mobile",
            partial: "admin/agenda_items/title_mobile",
            locals: { item: @agenda_item }
          )
        ]
      else
        head :unprocessable_entity
      end
    end

    def destroy
      @agenda_item = AgendaItem.find(params[:id])
      @agenda_item.destroy

      render turbo_stream: [
        turbo_stream.remove("agenda_item_#{@agenda_item.id}"),
        turbo_stream.remove("agenda_item_#{@agenda_item.id}_mobile")
      ]
    end

    private

    def agenda_item_params
      params.require(:agenda_item).permit(:title)
    end
  end
end
