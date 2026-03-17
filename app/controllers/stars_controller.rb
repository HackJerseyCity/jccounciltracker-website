class StarsController < ApplicationController
  layout "dashboard"

  STARRABLE_TYPES = %w[Meeting AgendaItem CouncilMember Tag].freeze

  def index
    @stars_by_type = Current.user.stars.includes(:starrable).group_by(&:starrable_type)
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
end
