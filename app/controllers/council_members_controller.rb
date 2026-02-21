class CouncilMembersController < ApplicationController
  allow_unauthenticated_access

  def index
    @current_members = CouncilMember
      .current
      .alphabetical
      .left_joins(:votes)
      .select("council_members.*, COUNT(votes.id) AS votes_count")
      .group("council_members.id")
  end

  def show
    @council_member = CouncilMember.find(params[:id])
    @votes = @council_member.votes
      .eager_load(agenda_item: [ :tags, { agenda_section: { agenda_version: :meeting } } ])
      .order("meetings.date DESC, agenda_items.item_number ASC")
  end
end
