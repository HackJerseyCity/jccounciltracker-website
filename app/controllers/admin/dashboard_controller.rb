module Admin
  class DashboardController < BaseController
    def show
      # --- Action items ---
      @draft_versions = AgendaVersion.draft
                          .includes(:meeting)
                          .order(created_at: :desc)
                          .limit(5)

      @meetings_without_minutes = Meeting.chronological
                                    .joins(:agenda_versions)
                                    .where(agenda_versions: { status: :published })
                                    .where.not(id: Meeting.joins(agenda_versions: { agenda_sections: { agenda_items: :votes } }).select(:id))
                                    .distinct
                                    .limit(5)

      @untagged_count = AgendaItem.left_joins(:agenda_item_tags)
                          .where(agenda_item_tags: { id: nil })
                          .count

      @total_items = AgendaItem.count
      @tagged_count = @total_items - @untagged_count

      # --- Stats ---
      @meeting_count = Meeting.count
      @published_count = AgendaVersion.published.select(:meeting_id).distinct.count
      @vote_count = Vote.count
      @user_count = User.count

      # --- Recent meetings ---
      @recent_meetings = Meeting.includes(agenda_versions: { agenda_sections: { agenda_items: :tags } })
                           .chronological
                           .limit(5)

      # --- User activity ---
      @recent_sessions = Session.includes(:user)
                           .order(created_at: :desc)
                           .limit(8)

      @new_users_7d = User.where("created_at >= ?", 7.days.ago).count
      @active_users_7d = Session.where("created_at >= ?", 7.days.ago)
                           .select(:user_id).distinct.count

      # --- Engagement ---
      @star_count = Star.count
      @stars_7d = Star.where("created_at >= ?", 7.days.ago).count

      @most_starred = Star.select("starrable_type, starrable_id, COUNT(*) AS star_count")
                        .group(:starrable_type, :starrable_id)
                        .order("star_count DESC")
                        .limit(5)
                        .map { |s| { type: s.starrable_type, id: s.starrable_id, count: s.star_count, record: s.starrable } }
                        .select { |s| s[:record].present? }

      @recently_starred = Star.includes(:starrable, :user)
                            .order(created_at: :desc)
                            .limit(5)
                            .select { |s| s.starrable.present? }

      # --- Tag coverage ---
      @tag_count = Tag.count
      @rules_count = TagRule.count
      @top_tags = Tag.left_joins(:agenda_item_tags)
                   .select("tags.*, COUNT(agenda_item_tags.id) AS items_count")
                   .group("tags.id")
                   .having("COUNT(agenda_item_tags.id) > 0")
                   .order("items_count DESC")
                   .limit(8)

      # --- Blog ---
      @draft_posts = BlogPost.draft.chronological.limit(3)

      # --- Audit log ---
      @recent_audit_logs = AdminAuditLog.includes(:user).recent.limit(10)
    end
  end
end
