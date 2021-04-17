class AddSourceMatchIdToTourMatches < ActiveRecord::Migration[5.2]
  def change
    add_column :tournament_matches, :source_match_id, :string, null: false, default: ''
  end
end
