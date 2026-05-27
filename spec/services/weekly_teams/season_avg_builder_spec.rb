RSpec.describe WeeklyTeams::SeasonAvgBuilder do
  subject(:result) { described_class.call(tournament.id, season.id) }

  let(:tournament) { Tournament.first }
  let!(:season)    { Season.last }

  def make_round
    create(:tournament_round, tournament: tournament, season: season)
  end

  context 'when no rounds exist for the tournament+season' do
    it { is_expected.to eq([]) }
  end

  context 'when rounds exist but all players have zero score' do
    before do
      round = make_round
      create(:round_player, :with_pos_por, score: 0, tournament_round: round)
    end

    it { is_expected.to eq([]) }
  end

  context 'with scored players across one round' do
    before do
      round = make_round
      create(:round_player, :with_pos_por, score: 7, tournament_round: round)
    end

    it 'returns one entry per team module' do
      expect(result.size).to eq(TeamModule.count)
    end

    it 'returns TeamModule as first element of each pair' do
      expect(result.first.first).to be_a(TeamModule)
    end

    it 'each team row has :slot and :entry keys' do
      _mod, team = result.first
      expect(team.first.keys).to contain_exactly(:slot, :entry)
    end

    it 'entry includes :appearances key' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry]).to include(:appearances)
    end
  end

  context 'when a player has scores in multiple rounds' do
    let(:player) { create(:player, :with_pos_por) }

    before do
      round1 = make_round
      round2 = make_round
      create(:round_player, player: player, club: player.club, score: 6, tournament_round: round1)
      create(:round_player, player: player, club: player.club, score: 8, tournament_round: round2)
    end

    it 'stores the average as total' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:total]).to eq(7.0)
    end

    it 'stores the count of appearances' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:appearances]).to eq(2)
    end

    it 'uses the best round_player as representative' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:round_player].score).to eq(8)
    end
  end

  context 'when two players compete for the same slot' do
    let(:por_low)  { create(:player, :with_pos_por) }
    let(:por_high) { create(:player, :with_pos_por) }

    before do
      round1 = make_round
      round2 = make_round
      # por_low avg = (5+5)/2 = 5.0
      create(:round_player, player: por_low,  club: por_low.club,  score: 5, tournament_round: round1)
      create(:round_player, player: por_low,  club: por_low.club,  score: 5, tournament_round: round2)
      # por_high avg = (9+7)/2 = 8.0
      create(:round_player, player: por_high, club: por_high.club, score: 9, tournament_round: round1)
      create(:round_player, player: por_high, club: por_high.club, score: 7, tournament_round: round2)
    end

    it 'assigns the player with the higher average' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).to eq(por_high)
    end

    it 'stores the average score as total' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:total]).to eq(8.0)
    end
  end

  context 'when a player has fewer appearances than 50% of season rounds' do
    let(:regular) { create(:player, :with_pos_por) }
    let(:sporadic) { create(:player, :with_pos_por) }

    before do
      # 4 rounds in the season → min = ceil(4 * 0.5) = 2
      rounds = Array.new(4) { make_round }
      # regular plays all 4 rounds
      rounds.each { |r| create(:round_player, player: regular, club: regular.club, score: 7, tournament_round: r) }
      # sporadic plays only 1 round (below threshold)
      create(:round_player, player: sporadic, club: sporadic.club, score: 9, tournament_round: rounds.first)
    end

    it 'excludes players below 50% appearances' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).to eq(regular)
    end

    it 'does not include the sporadic player even with a higher score' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).not_to eq(sporadic)
    end
  end

  context 'when a player has exactly 50% appearances' do
    let(:player) { create(:player, :with_pos_por) }

    before do
      # 4 rounds → min = 2; player plays exactly 2
      rounds = Array.new(4) { make_round }
      rounds.first(2).each { |r| create(:round_player, player: player, club: player.club, score: 7, tournament_round: r) }
    end

    it 'includes the player' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).to eq(player)
    end
  end

  context 'when rounds belong to a different tournament' do
    before do
      other_tournament = create(:tournament)
      other_round = create(:tournament_round, tournament: other_tournament, season: season)
      create(:round_player, :with_pos_por, score: 9, tournament_round: other_round)
    end

    it { is_expected.to eq([]) }
  end

  context 'when rounds belong to a different season' do
    before do
      other_season = create(:season)
      other_round = create(:tournament_round, tournament: tournament, season: other_season)
      create(:round_player, :with_pos_por, score: 9, tournament_round: other_round)
    end

    it { is_expected.to eq([]) }
  end

  context 'when the same player is eligible for multiple slots' do
    before do
      round = make_round
      create(:round_player, :with_pos_por, score: 8, tournament_round: round)
      create_list(:round_player, 3, :with_pos_dc, score: 7, tournament_round: round)
    end

    it 'does not assign the same player to two slots in any module' do
      result.each do |(_mod, team)|
        assigned_ids = team.filter_map { |row| row.dig(:entry, :player)&.id }
        expect(assigned_ids).to eq(assigned_ids.uniq)
      end
    end
  end
end
