module Auditable
  extend ActiveSupport::Concern

  private

  def audit(action, target: nil, metadata: {})
    AdminAuditLog.log(action: action, target: target, metadata: metadata)
  end
end
