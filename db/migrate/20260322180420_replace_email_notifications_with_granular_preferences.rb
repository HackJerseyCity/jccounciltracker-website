class ReplaceEmailNotificationsWithGranularPreferences < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :email_council_updates, :boolean, default: true, null: false
    add_column :users, :email_blog, :boolean, default: true, null: false
    add_column :users, :email_marketing, :boolean, default: true, null: false

    # Preserve existing opt-outs
    execute <<~SQL
      UPDATE users
      SET email_council_updates = email_notifications,
          email_blog = email_notifications,
          email_marketing = email_notifications
    SQL

    remove_column :users, :email_notifications
  end

  def down
    add_column :users, :email_notifications, :boolean, default: true, null: false

    # If any preference is off, mark as unsubscribed
    execute <<~SQL
      UPDATE users
      SET email_notifications = (email_council_updates AND email_blog AND email_marketing)
    SQL

    remove_column :users, :email_council_updates
    remove_column :users, :email_blog
    remove_column :users, :email_marketing
  end
end
