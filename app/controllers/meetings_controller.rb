class MeetingsController < ApplicationController
  allow_unauthenticated_access
  layout "dashboard"

  def index
    @meetings = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).chronological
  end

  def show
    @meeting = Meeting.includes(agenda_versions: { agenda_sections: { agenda_items: [ :tags, { votes: :council_member } ] } }).find(params[:id])
    @agenda_version = if params[:version].present?
      @meeting.published_versions.find_by(version_number: params[:version])
    else
      @meeting.current_published_version
    end
    @agenda_sections = @agenda_version&.agenda_sections || AgendaSection.none

    if Current.user
      agenda_item_ids = @agenda_sections.flat_map { |s| s.agenda_items.map(&:id) }
      @starred_item_ids = Current.user.stars.where(starrable_type: "AgendaItem", starrable_id: agenda_item_ids).pluck(:starrable_id).to_set
      @starred_meeting = Current.user.stars.exists?(starrable: @meeting)
    end
  end
end
