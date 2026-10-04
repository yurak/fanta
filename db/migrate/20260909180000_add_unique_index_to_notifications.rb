class AddUniqueIndexToNotifications < ActiveRecord::Migration[8.0]
  INDEX_NAME = 'index_notifications_on_team_notifiable_and_kind'.freeze

  # Notifications::Creator skips teams it has already notified, but that check and the insert are
  # two separate statements: two overlapping runs can both read "not notified yet" and both write.
  # The index makes the duplicate impossible rather than unlikely.
  def change
    add_index :notifications, %i[team_id notifiable_type notifiable_id kind],
              unique: true, name: INDEX_NAME
  end
end
