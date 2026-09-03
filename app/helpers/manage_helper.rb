module ManageHelper
  TOURNAMENT_ICON_SIZE = 28

  def manage_tournament_icon(tournament)
    return '—' unless tournament

    image_tag(tournament.logo_path, width: TOURNAMENT_ICON_SIZE, height: TOURNAMENT_ICON_SIZE,
                                    title: tournament.name, alt: tournament.name)
  end

  # Shared nav items for the manage section.
  # Each item: [controller_path, url, icon, label_key]
  def manage_nav_items
    [
      ['manage/tournament_rounds', manage_tournament_rounds_path, 'icons/round/round.svg', 'manage.nav.tournament_rounds'],
      ['manage/joins', manage_joins_path, 'icons/round/join.svg', 'manage.nav.joins'],
      ['manage/users', manage_users_path, 'icons/round/users.svg', 'manage.nav.users'],
      ['manage/user_logos', manage_user_logos_path, 'icons/round/image.svg', 'manage.nav.user_logos'],
      ['manage/teams', manage_teams_path, 'icons/round/teams.svg', 'manage.nav.teams'],
      ['manage/leagues', manage_leagues_path, 'icons/round/table.svg', 'manage.nav.leagues'],
      ['manage/auctions', manage_auctions_path, 'icons/round/auctions.svg', 'manage.nav.auctions'],
      ['manage/players', manage_players_path, 'icons/round/players.svg', 'manage.nav.players'],
      ['manage/clubs', manage_clubs_path, 'icons/round/clubs.svg', 'manage.nav.clubs'],
      ['manage/club_transfers', manage_club_transfers_path, 'icons/round/transfer.svg', 'manage.nav.club_transfers'],
      ['manage/club_transfer_requests', manage_club_transfer_requests_path, 'icons/round/request.svg',
       'manage.nav.club_transfer_requests'],
      ['manage/tournaments', manage_tournaments_path, 'icons/round/statistics.svg', 'manage.nav.tournaments'],
      ['manage/national_teams', manage_national_teams_path, 'icons/round/teams.svg', 'manage.nav.national_teams'],
      ['manage/weekly_teams', manage_weekly_teams_path, 'icons/round/star.svg', 'manage.nav.weekly_team'],
      ['manage/champions', manage_champions_path, 'icons/round/crown.svg', 'manage.nav.champions']
    ]
  end

  # round deadline in the admin's local time, e.g. "22:30 22/12/26", or a placeholder when unset
  def tour_dashboard_deadline(deadline)
    current_user.local_time(deadline, '%H:%M %d/%m/%y') || '--:--'
  end

  # when the round auto-closes (moderation time + TournamentRound::MODERATED_HOURS) in the admin's
  # local time, or nil when the round has not been moderated yet
  def tour_dashboard_closing_time(round)
    return unless round.closing_time

    current_user.local_time(round.closing_time, '%H:%M %d/%m/%y')
  end
end
