class MeetingsController < ApplicationController
  allow_unauthenticated_access

  def index
    @meetings = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).chronological
  end

  def show
    @meeting = Meeting.includes(agenda_versions: { agenda_sections: { agenda_items: [ :tags, { votes: :council_member } ] } }).find(params[:id])
    @agenda_version = if params[:version].present?
      @meeting.version(params[:version])
    else
      @meeting.current_version
    end
    @agenda_sections = @agenda_version&.agenda_sections || AgendaSection.none
  end
end
