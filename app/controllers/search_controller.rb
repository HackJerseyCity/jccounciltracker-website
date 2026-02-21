class SearchController < ApplicationController
  allow_unauthenticated_access

  PER_PAGE = 25

  def index
    @council_members = CouncilMember.current.alphabetical
    @tags = Tag.alphabetical
    @selected_member_id = params[:council_member_id]

    if any_filters?
      scope = base_scope
      scope = apply_text_filter(scope)
      scope = apply_file_number_filter(scope)
      scope = apply_council_member_filter(scope)
      scope = apply_tag_filter(scope)
      scope = apply_date_filters(scope)
      scope = apply_result_filter(scope)

      @total_count = scope.count
      @page = [ params[:page].to_i, 1 ].max
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @agenda_items = scope.order("meetings.date DESC, agenda_items.position ASC")
                           .limit(PER_PAGE)
                           .offset((@page - 1) * PER_PAGE)

      if @selected_member_id.present?
        item_ids = @agenda_items.map(&:id)
        @votes_by_item = Vote.where(agenda_item_id: item_ids, council_member_id: @selected_member_id)
                             .index_by(&:agenda_item_id)
      end

      @has_results = @agenda_items.any?
    end
  end

  private

  def base_scope
    AgendaItem.joins(agenda_section: { agenda_version: :meeting })
              .includes(:tags, agenda_section: { agenda_version: :meeting })
              .where(agenda_versions: { status: :published })
  end

  def any_filters?
    params[:q].present? ||
      params[:file_number].present? ||
      params[:council_member_id].present? ||
      params[:tag_id].present? ||
      params[:date_from].present? ||
      params[:date_to].present? ||
      (params[:result].present? && AgendaItem::VALID_RESULTS.include?(params[:result]))
  end

  def apply_text_filter(scope)
    return scope unless params[:q].present?

    scope.where("agenda_items.title LIKE ?", "%#{sanitize_sql_like(params[:q])}%")
  end

  def apply_file_number_filter(scope)
    return scope unless params[:file_number].present?

    scope.where("agenda_items.file_number LIKE ?", "%#{sanitize_sql_like(params[:file_number])}%")
  end

  def apply_council_member_filter(scope)
    return scope unless params[:council_member_id].present?

    scope = scope.joins(:votes).where(votes: { council_member_id: params[:council_member_id] })
    scope = scope.where(votes: { position: params[:vote_position] }) if params[:vote_position].present?
    scope
  end

  def apply_tag_filter(scope)
    return scope unless params[:tag_id].present?

    scope.joins(:agenda_item_tags).where(agenda_item_tags: { tag_id: params[:tag_id] })
  end

  def apply_date_filters(scope)
    if params[:date_from].present?
      date_from = Date.parse(params[:date_from]) rescue nil
      scope = scope.where("meetings.date >= ?", date_from) if date_from
    end

    if params[:date_to].present?
      date_to = Date.parse(params[:date_to]) rescue nil
      scope = scope.where("meetings.date <= ?", date_to) if date_to
    end

    scope
  end

  def apply_result_filter(scope)
    return scope unless params[:result].present?
    return scope unless AgendaItem::VALID_RESULTS.include?(params[:result])

    scope.where(agenda_items: { result: params[:result] })
  end

  def sanitize_sql_like(string)
    ActiveRecord::Base.sanitize_sql_like(string)
  end
end
