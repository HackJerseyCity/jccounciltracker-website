class TagsController < ApplicationController
  allow_unauthenticated_access

  def index
    @tags = Tag.alphabetical
      .left_joins(agenda_item_tags: { agenda_item: { agenda_section: :agenda_version } })
      .where(agenda_versions: { status: :published })
      .select("tags.*, COUNT(agenda_item_tags.id) AS agenda_items_count")
      .group("tags.id")
      .having("COUNT(agenda_item_tags.id) > 0")
  end

  def show
    @tag = Tag.find(params[:id])
    @agenda_items = @tag.agenda_items
      .joins(agenda_section: :agenda_version)
      .where(agenda_versions: { status: :published })
      .includes(:tags, agenda_section: { agenda_version: :meeting })
      .order("meetings.date DESC, agenda_items.item_number ASC")
  end
end
