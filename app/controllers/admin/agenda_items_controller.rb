module Admin
  class AgendaItemsController < BaseController
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

    private

    def agenda_item_params
      params.require(:agenda_item).permit(:title)
    end
  end
end
