require "test_helper"
require "rake"

class AdminRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:generate_site_admin")
  end

  test "generate_site_admin creates a site admin" do
    Invitation.where(invited_by: User.site_admin).delete_all
    Session.where(user: User.site_admin).delete_all
    BlogPost.where(user: User.site_admin).delete_all
    Star.where(user: User.site_admin).delete_all
    User.where(role: :site_admin).delete_all

    assert_difference "User.site_admin.count", 1 do
      Rake::Task["admin:generate_site_admin"].invoke
    end

    admin = User.site_admin.last
    assert_equal "admin@counciltracker.org", admin.email_address
    assert_equal "Site Admin", admin.name
    assert admin.site_admin?
  ensure
    Rake::Task["admin:generate_site_admin"].reenable
  end

  test "generate_site_admin refuses when site admin exists" do
    assert User.site_admin.exists?, "Fixture site_admin should exist"

    assert_raises(SystemExit) do
      Rake::Task["admin:generate_site_admin"].invoke
    end
  ensure
    Rake::Task["admin:generate_site_admin"].reenable
  end
end
