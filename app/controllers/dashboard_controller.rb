class DashboardController < ApplicationController
  allow_unauthenticated_access
  layout "dashboard"

  def show
    @recent_meetings = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).chronological.limit(3)
    @current_members = CouncilMember.current.alphabetical.limit(6)
    @top_tags = Tag.alphabetical
      .left_joins(agenda_item_tags: { agenda_item: { agenda_section: :agenda_version } })
      .where(agenda_versions: { status: :published })
      .select("tags.*, COUNT(agenda_item_tags.id) AS agenda_items_count")
      .group("tags.id")
      .having("COUNT(agenda_item_tags.id) > 0")
      .order("agenda_items_count DESC")
      .limit(8)
  end
end
