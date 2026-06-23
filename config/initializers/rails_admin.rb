RailsAdmin.config do |config|
  config.asset_source = :webpacker
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == CancanCan ==
  config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.model 'Auction' do
    list do
      exclude_fields :auction_rounds, :transfers
    end
  end

  config.model 'AuctionBid' do
    list do
      exclude_fields :player_bids
    end
  end

  config.model 'AuctionRound' do
    list do
      exclude_fields :auction_bids, :player_bids
    end
  end

  config.model 'Club' do
    list do
      exclude_fields :players, :player_season_stats, :host_tournament_matches, :guest_tournament_matches
    end
  end

  config.model 'Division' do
    list do
      exclude_fields :leagues
    end
  end

  config.model 'League' do
    list do
      exclude_fields :auctions, :transfers, :tours, :players, :results, :teams
    end
  end

  config.model 'Lineup' do
    list do
      exclude_fields :match_players
    end
  end

  config.model 'MatchPlayer' do
    list do
      exclude_fields :main_subs, :reserve_subs
    end
  end

  config.model 'NationalTeam' do
    list do
      exclude_fields :players, :host_national_matches, :guest_national_matches
    end
  end

  config.model 'Player' do
    list do
      scopes [:with_admin_includes]
      exclude_fields :player_positions, :player_teams, :player_bids, :player_requests, :player_season_stats, :round_players, :transfers
    end
  end

  config.model 'Position' do
    list do
      exclude_fields :players, :player_positions
    end
  end

  config.model 'Result' do
    list do
      scopes [:with_admin_includes]
    end
  end

  config.model 'RoundPlayer' do
    list do
      exclude_fields :match_players, :lineups, :in_subs, :out_subs
    end
  end

  config.model 'Season' do
    list do
      exclude_fields :leagues, :tournament_rounds, :player_season_stats
    end
  end

  config.model 'Team' do
    list do
      exclude_fields :join, :auction_bids, :player_teams, :players, :lineups, :host_matches, :guest_matches, :results, :transfers
    end
  end

  config.model 'TeamModule' do
    list do
      exclude_fields :slots, :lineups
    end
  end

  config.model 'Tour' do
    list do
      exclude_fields :matches, :lineups, :round_players
    end
  end

  config.model 'Tournament' do
    list do
      exclude_fields :article_tags, :clubs, :ec_clubs, :leagues, :links, :joins,
                     :national_teams, :player_season_stats, :tournament_rounds
    end
  end

  config.model 'TournamentRound' do
    list do
      exclude_fields :round_players, :national_matches, :tournament_matches, :tours, :lineups
    end
  end

  config.model 'User' do
    list do
      exclude_fields :joins, :teams, :leagues, :results, :player_requests, :user_titles, :user_profile, :lineups, :transfers
    end
  end

  config.model 'UserTitle' do
    list do
      scopes [:with_admin_includes]
    end
  end

  config.model 'WeeklyTeam' do
    list do
      exclude_fields :weekly_team_players
    end
  end

  config.model 'WeeklyTeamPlayer' do
    list do
      scopes [:with_admin_includes]
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
