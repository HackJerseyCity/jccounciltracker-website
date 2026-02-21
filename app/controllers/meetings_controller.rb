class MeetingsController < ApplicationController
  allow_unauthenticated_access

  def index
    @meetings = Meeting.chronological
  end

  def show
    @meeting = Meeting.includes(agenda_sections: :agenda_items).find(params[:id])
  end
end
