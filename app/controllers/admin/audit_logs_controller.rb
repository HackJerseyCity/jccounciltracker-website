module Admin
  class AuditLogsController < BaseController
    before_action :require_site_admin

    def index
      @audit_logs = AdminAuditLog.includes(:user).recent

      if params[:action_filter].present?
        @audit_logs = @audit_logs.where(action: params[:action_filter])
      end

      if params[:user_id].present?
        @audit_logs = @audit_logs.where(user_id: params[:user_id])
      end

      @audit_logs = @audit_logs.limit(100)
      @action_types = AdminAuditLog.distinct.pluck(:action).sort
      @admin_users = User.where(role: [ :content_admin, :site_admin ]).order(:name)
    end
  end
end
