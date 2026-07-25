require 'rails_helper'

RSpec.describe 'Api::Players stats export' do
  describe 'GET /api/players/stats_export' do
    let(:season) { Season.last }
    let(:tournament) { create(:tournament) }
    let(:club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: club) }

    before do
      create(:player_season_stat, player: player, club: club, season: season, tournament: tournament,
                                  played_matches: 8, score: 7.0, final_score: 7.5)
    end

    it 'responds successfully' do
      get stats_export_api_players_path

      expect(response).to have_http_status(:ok)
    end

    it 'returns a CSV media type' do
      get stats_export_api_players_path

      expect(response.media_type).to eq('text/csv')
    end

    it 'sets a season-named attachment filename' do
      get stats_export_api_players_path

      expect(response.headers['Content-Disposition'])
        .to include("players_stats_#{season.start_year}_#{season.end_year}.csv")
    end

    it 'includes the header row and player data' do
      get stats_export_api_players_path

      expect(response.body).to include('player,club').and include(player.full_name_reverse)
    end

    it 'exports the requested season only' do
      other = create(:season, start_year: 2098, end_year: 2099)
      create(:player_season_stat, player: create(:player, club: club), club: club,
                                  season: other, tournament: tournament, played_matches: 3)

      get stats_export_api_players_path(filter: { season_id: other.id })

      expect(response.body.lines.size).to eq(2) # header + 1 row
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
