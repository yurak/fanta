class AddSourceCalendarUrlToTournament < ActiveRecord::Migration[5.2]
  def change
    add_column :tournaments, :source_calendar_url, :string, null: false, default: ''
  end
end
