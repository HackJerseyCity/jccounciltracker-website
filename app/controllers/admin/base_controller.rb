module Admin
  class BaseController < ApplicationController
    include Auditable

    before_action :require_content_admin_or_above

    layout "admin"
  end
end
