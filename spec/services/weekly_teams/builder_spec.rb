RSpec.describe WeeklyTeams::Builder do
  subject(:result) { described_class.call(round_ids) }

  let(:round) { create(:tournament_round) }

  context 'when round_ids is blank' do
    let(:round_ids) { [] }

    it { is_expected.to eq([]) }
  end

  context 'with scored round players' do
    let(:round_ids) { [round.id] }

    before do
      create(:round_player, :with_pos_por, score: 7, tournament_round: round)
    end

    it 'returns one entry per team module' do
      expect(result.size).to eq(TeamModule.count)
    end

    it 'returns TeamModule as first element of each pair' do
      expect(result.first.first).to be_a(TeamModule)
    end

    it 'returns Array as second element of each pair' do
      expect(result.first.last).to be_an(Array)
    end

    it 'each team row has :slot and :entry keys' do
      _mod, team = result.first
      expect(team.first.keys).to contain_exactly(:slot, :entry)
    end

    it 'each team has 11 rows' do
      _mod, team = result.first
      expect(team.size).to eq(11)
    end
  end

  context 'when two players compete for the same slot' do
    let(:round_ids) { [round.id] }
    let(:por_low)   { create(:round_player, :with_pos_por, score: 5, tournament_round: round) }
    let(:por_high)  { create(:round_player, :with_pos_por, score: 9, tournament_round: round) }

    before do
      por_low
      por_high
    end

    it 'assigns the highest scoring player to the slot' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).to eq(por_high.player)
    end

    it 'includes the correct score' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:total]).to eq(por_high.result_score)
    end

    it 'includes the correct round_player' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:round_player]).to eq(por_high)
    end
  end

  context 'when a player appears in multiple selected rounds' do
    let(:round2)    { create(:tournament_round) }
    let(:round_ids) { [round.id, round2.id] }

    let(:por_multi) do
      player = create(:player, :with_pos_por)
      create(:round_player, player: player, club: player.club, score: 7, tournament_round: round)
      create(:round_player, player: player, club: player.club, score: 8, tournament_round: round2)
      player
    end
    let(:por_single) do
      player = create(:player, :with_pos_por)
      create(:round_player, player: player, club: player.club, score: 12, tournament_round: round)
      player
    end

    before do
      por_multi
      por_single
    end

    it 'uses the max score per round, not the sum' do
      # por_multi: sum=15 but max=8; por_single: max=12 — should win
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:player]).to eq(por_single)
    end

    it 'tracks the round_player with the max score' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry][:round_player].player).to eq(por_single)
    end
  end

  context 'when a player has zero score' do
    let(:round_ids) { [round.id] }

    before do
      create(:round_player, :with_pos_por, score: 0, tournament_round: round)
    end

    it 'leaves the slot empty' do
      _mod, team = result.first
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry]).to be_nil
    end
  end

  context 'when there are not enough players to fill a position' do
    let(:round_ids) { [round.id] }

    before do
      create(:round_player, :with_pos_dc, score: 8, tournament_round: round)
    end

    it 'returns nil entries for unfilled slots' do
      _mod, team = result.find { |(mod, _)| mod.name == '4-3-3' }
      por_row = team.find { |row| row[:slot].position == 'Por' }
      expect(por_row[:entry]).to be_nil
    end
  end

  context 'when the same player is eligible for multiple slots' do
    let(:round_ids) { [round.id] }

    before do
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

  context 'when mode is flop' do
    subject(:result) { described_class.call(round_ids, mode: :flop) }

    let(:round_ids) { [round.id] }

    context 'when two players compete for the same slot' do
      let(:por_bad)  { create(:round_player, :with_pos_por, score: 3, tournament_round: round) }
      let(:por_good) { create(:round_player, :with_pos_por, score: 9, tournament_round: round) }

      before do
        por_bad
        por_good
      end

      it 'assigns the lowest scoring player to the slot' do
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry][:player]).to eq(por_bad.player)
      end

      it 'includes the correct round_player' do
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry][:round_player]).to eq(por_bad)
      end
    end

    context 'when a player has zero score' do
      before do
        create(:round_player, :with_pos_por, score: 0, tournament_round: round)
        create(:round_player, :with_pos_por, score: 3, tournament_round: round)
      end

      it 'assigns a non-zero player to the slot' do
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry]).not_to be_nil
      end

      it 'assigns a player with positive score' do
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry][:total]).to be_positive
      end
    end

    context 'when a player appears in multiple rounds' do
      let(:round2)    { create(:tournament_round) }
      let(:round_ids) { [round.id, round2.id] }

      let(:por_multi) do
        player = create(:player, :with_pos_por)
        create(:round_player, player: player, club: player.club, score: 3, tournament_round: round)
        create(:round_player, player: player, club: player.club, score: 9, tournament_round: round2)
        player
      end
      let(:por_single) do
        player = create(:player, :with_pos_por)
        create(:round_player, player: player, club: player.club, score: 5, tournament_round: round)
        player
      end

      before do
        por_multi
        por_single
      end

      it 'uses the min score across rounds, not max' do
        # por_multi: min=3; por_single: min=5 — por_multi should win (worse)
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry][:player]).to eq(por_multi)
      end

      it 'tracks the round_player with the min score' do
        _mod, team = result.first
        por_row = team.find { |row| row[:slot].position == 'Por' }
        expect(por_row[:entry][:round_player].score).to eq(3)
      end
    end
  end
end
