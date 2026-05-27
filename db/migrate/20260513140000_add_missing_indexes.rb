class AddMissingIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :match_players, :lineup_id, if_not_exists: true

    add_index :lineups, :tour_id, if_not_exists: true
    add_index :lineups, :team_id, if_not_exists: true

    add_index :substitutes, :main_mp_id, if_not_exists: true
    add_index :substitutes, :reserve_mp_id, if_not_exists: true
    add_index :substitutes, :in_rp_id, if_not_exists: true
    add_index :substitutes, :out_rp_id, if_not_exists: true

    add_index :round_players, :club_id, if_not_exists: true

    add_index :players, :club_id, if_not_exists: true

    add_index :matches, :tour_id, if_not_exists: true
    add_index :matches, :host_id, if_not_exists: true
    add_index :matches, :guest_id, if_not_exists: true

    add_index :slots, :team_module_id, if_not_exists: true

    add_index :tournament_matches, :host_club_id, if_not_exists: true
    add_index :tournament_matches, :guest_club_id, if_not_exists: true

    add_index :user_profiles, :user_id, if_not_exists: true
  end
end
