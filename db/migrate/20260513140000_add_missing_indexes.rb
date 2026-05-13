class AddMissingIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :match_players, :lineup_id

    add_index :lineups, :tour_id
    add_index :lineups, :team_id

    add_index :substitutes, :main_mp_id
    add_index :substitutes, :reserve_mp_id
    add_index :substitutes, :in_rp_id
    add_index :substitutes, :out_rp_id

    add_index :round_players, :club_id

    add_index :players, :club_id

    add_index :matches, :tour_id
    add_index :matches, :host_id
    add_index :matches, :guest_id

    add_index :slots, :team_module_id

    add_index :tournament_matches, :host_club_id
    add_index :tournament_matches, :guest_club_id

    add_index :user_profiles, :user_id
  end
end
