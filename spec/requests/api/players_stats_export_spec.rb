require 'rails_helper'
require 'csv'

RSpec.describe 'Api::Players stats export' do
  describe 'GET /api/players/stats_export' do
    let(:season) { Season.last }
    let(:tournament) { create(:tournament) }
    let(:club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: club) }

    login_user

    before do
      create(:player_season_stat, player: player, club: club, season: season, tournament: tournament,
                                  played_matches: 8, score: 7.0, final_score: 7.5)
    end

    context 'when the user is logged out' do
      before do
        sign_out :user
        get stats_export_api_players_path
      end

      it 'does not build the export' do
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    it 'responds successfully' do
      get stats_export_api_players_path

      expect(response).to have_http_status(:ok)
    end

    it 'returns a CSV media type' do
      get stats_export_api_players_path

      expect(response.media_type).to eq('text/csv')
    end

    it 'sets a season-named, timestamped attachment filename' do
      get stats_export_api_players_path

      expect(response.headers['Content-Disposition'])
        .to match(/players_stats_#{season.start_year}_#{season.end_year}_\d{8}_\d{6}\.csv/)
    end

    it 'includes the header row and player data' do
      get stats_export_api_players_path

      expect(response.body).to include('player,club').and include(player.full_name_reverse)
    end

    it 'reports zero stats for a current player who did not play the requested season' do
      other = create(:season, start_year: 2098, end_year: 2099)

      get stats_export_api_players_path(filter: { season_id: other.id })

      # the player has stats only in `season`, not `other`, but is still listed with zeros
      player_row = CSV.parse(response.body).find { |row| row[0].to_s.include?(player.full_name_reverse) }
      expect(player_row[7]).to eq('0') # played matches
    end

    context 'when filtered by selected clubs' do
      before do
        other_club = create(:club, tournament: tournament)
        create(:player_season_stat, player: create(:player, club: other_club), club: other_club,
                                    season: season, tournament: tournament, played_matches: 4)

        get stats_export_api_players_path(filter: { season_id: season.id, club_id: [club.id] })
      end

      it 'exports only players from the selected clubs' do
        expect(response.body.lines.size).to eq(2) # header + only the club's player
      end

      it 'includes the selected club player' do
        expect(response.body).to include(player.full_name_reverse)
      end
    end
  end
end
