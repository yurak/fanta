require 'csv'

RSpec.describe Players::StatsCsv do
  describe '.call' do
    let(:season) { create(:season, start_year: 2024, end_year: 2025) }
    let(:tournament) { create(:tournament) }
    let(:club) { create(:club, tournament: tournament, name: 'Arsenal') }
    let(:player) { create(:player, name: 'Saka', first_name: 'Bukayo', club: club) }

    let(:rows) { CSV.parse(described_class.call(season: season, player_ids: player_ids)) }
    let(:player_ids) { nil }

    before do
      create(:player_season_stat, player: player, club: club, season: season, tournament: tournament,
                                  played_matches: 10, score: 7.5, final_score: 8.0, goals: 4)
    end

    it 'writes a header row' do
      expect(rows.first).to eq(Players::StatsCsv::HEADERS)
    end

    it 'writes one data row per player' do
      expect(rows.size).to eq(2)
    end

    it 'includes the player name, club and stats' do
      expect(rows.last).to include('Saka Bukayo', 'Arsenal', '10', '4')
    end

    context 'with current player positions' do
      before do
        position = create(:position, name: 'Cd', human_name: 'ЦЗ')
        create(:player_position, player: player, position: position)
      end

      it 'exports the player current positions' do
        expect(rows.last).to include('ЦЗ')
      end
    end

    context 'when the player appeared for two clubs in the season' do
      let(:other_club) { create(:club, tournament: tournament, name: 'Chelsea') }

      before do
        # player moved to `club` (Arsenal), also played for `other_club` earlier in the season
        create(:player_season_stat, player: player, club: other_club, season: season, tournament: tournament,
                                    played_matches: 30, score: 8.5, final_score: 9.0, goals: 6)
      end

      it 'aggregates both clubs into a single row' do
        expect(rows.size).to eq(2) # header + one aggregated row
      end

      it 'sums the counting stats' do
        expect(rows.last).to include('40', '10') # played_matches 10+30, goals 4+6
      end

      it 'weights the scores by played matches, formatted with a comma decimal' do
        # base: (7.5*10 + 8.5*30) / 40 = 8.25 ; total: (8.0*10 + 9.0*30) / 40 = 8.75
        expect(rows.last).to include('8,25', '8,75')
      end

      it 'lists all clubs the player had stats for that season' do
        expect(rows.last.last).to eq('Arsenal, Chelsea')
      end
    end

    context 'when a current player has no stats for the season' do
      before { create(:player, name: 'Nostat', first_name: 'No', club: club) }

      it 'still includes the player with zero stats' do
        nostat_row = rows.find { |row| row[0].to_s.include?('Nostat') }

        expect(nostat_row[7]).to eq('0') # played matches
      end

      it 'leaves the season clubs column empty for that player' do
        nostat_row = rows.find { |row| row[0].to_s.include?('Nostat') }

        expect(nostat_row.last).to eq('')
      end
    end

    context 'with a stat from another season' do
      before do
        other = create(:season, start_year: 2023, end_year: 2024)
        create(:player_season_stat, player: player, club: club, season: other, tournament: tournament,
                                    played_matches: 5)
      end

      it 'exports only the requested season' do
        expect(rows.size).to eq(2)
      end
    end

    context 'when filtered by player_ids' do
      let(:player_ids) { [player.id] }

      before do
        other_player = create(:player, club: club)
        create(:player_season_stat, player: other_player, club: club,
                                    season: season, tournament: tournament, played_matches: 3)
      end

      it 'exports only the given players' do
        expect(rows.size).to eq(2)
      end
    end
  end
end
