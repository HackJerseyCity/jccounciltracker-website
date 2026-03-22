class StarsController < ApplicationController
  layout "dashboard"

  STARRABLE_TYPES = %w[Meeting AgendaItem CouncilMember Tag].freeze

  TYPE_LABELS = {
    "Meeting" => "Meetings",
    "AgendaItem" => "Agenda Items",
    "CouncilMember" => "Council Members",
    "Tag" => "Topics"
  }.freeze

  def index
    stars = Current.user.stars.includes(:starrable).order(created_at: :desc)

    if params[:type].present? && STARRABLE_TYPES.include?(params[:type])
      @active_type = params[:type]
      stars = stars.where(starrable_type: @active_type)
    end

    @stars = stars.select { |s| s.starrable.present? }

    if params[:q].present?
      query = params[:q].downcase
      @stars = @stars.select { |s| star_matches_query?(s, query) }
    end

    @type_counts = Current.user.stars.group(:starrable_type).count
    @total_count = @type_counts.values.sum
  end

  def create
    starrable = find_starrable
    return head :unprocessable_entity unless starrable

    @star = Current.user.stars.find_or_create_by(starrable: starrable)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id_for_star_button(starrable), partial: "stars/button", locals: { starrable: starrable, starred: true }) }
      format.html { redirect_back fallback_location: stars_path }
    end
  end

  def destroy
    @star = Current.user.stars.find(params[:id])
    starrable = @star.starrable
    @star.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id_for_star_button(starrable), partial: "stars/button", locals: { starrable: starrable, starred: false }) }
      format.html { redirect_back fallback_location: stars_path }
    end
  end

  private

  def find_starrable
    type = params[:starrable_type]
    return unless STARRABLE_TYPES.include?(type)

    type.constantize.find_by(id: params[:starrable_id])
  end

  def dom_id_for_star_button(starrable)
    "star_button_#{starrable.class.name.underscore}_#{starrable.id}"
  end

  def star_matches_query?(star, query)
    item = star.starrable
    case star.starrable_type
    when "Meeting"
      item.display_name.downcase.include?(query)
    when "AgendaItem"
      item.title.downcase.include?(query) || item.item_number.downcase.include?(query) ||
        item.file_number.to_s.downcase.include?(query)
    when "CouncilMember"
      item.display_name.downcase.include?(query)
    when "Tag"
      item.name.downcase.include?(query)
    else
      false
    end
  end
end
