RSpec.describe WeeklyTeams::Saver do
  subject(:result) do
    described_class.call(
      team_module_id: team_module.id,
      round_ids: [round.id],
      mode: 'top',
      number: 1,
      players: players
    )
  end

  let(:team_module)  { TeamModule.first }
  let(:slot)         { team_module.slots.first }
  let(:round)        { create(:tournament_round) }
  let(:round_player) { create(:round_player, :with_pos_por, score: 8, tournament_round: round) }
  let(:players)      { [{ slot_id: slot.id, round_player_id: round_player.id, total: 8.0 }] }

  before { round_player }

  context 'with valid params' do
    it 'returns a WeeklyTeam' do
      expect(result).to be_a(WeeklyTeam)
    end

    it 'persists the WeeklyTeam' do
      expect { result }.to change(WeeklyTeam, :count).by(1)
    end

    it 'creates players for filled slots' do
      expect(result.weekly_team_players.count).to eq(1)
    end

    it 'sets the correct mode' do
      expect(result.mode).to eq('top')
    end

    it 'sets the correct number' do
      expect(result.number).to eq(1)
    end

    it 'sets the round_ids' do
      expect(result.round_ids).to eq([round.id])
    end

    it 'sets the team_module' do
      expect(result.team_module).to eq(team_module)
    end

    it 'sets the current season' do
      expect(result.season).to eq(Season.order(:start_year).last)
    end

    it 'stores total on each player' do
      expect(result.weekly_team_players.first.total).to eq(8.0)
    end

    it 'stores round_player on each player' do
      expect(result.weekly_team_players.first.round_player).to eq(round_player)
    end
  end

  context 'when team_module_id is invalid' do
    subject(:result) do
      described_class.call(
        team_module_id: 0,
        round_ids: [round.id],
        mode: 'top',
        number: 1,
        players: players
      )
    end

    it { is_expected.to be_nil }

    it 'does not create a WeeklyTeam' do
      expect { result }.not_to change(WeeklyTeam, :count)
    end
  end

  context 'when number is zero' do
    subject(:result) do
      described_class.call(
        team_module_id: team_module.id,
        round_ids: [round.id],
        mode: 'top',
        number: 0,
        players: players
      )
    end

    it { is_expected.to be_nil }

    it 'does not create a WeeklyTeam' do
      expect { result }.not_to change(WeeklyTeam, :count)
    end
  end

  context 'when mode is flop' do
    subject(:result) do
      described_class.call(
        team_module_id: team_module.id,
        round_ids: [round.id],
        mode: 'flop',
        number: 2,
        players: players
      )
    end

    it 'sets flop mode' do
      expect(result.mode).to eq('flop')
    end

    it 'persists the WeeklyTeam' do
      expect { result }.to change(WeeklyTeam, :count).by(1)
    end
  end

  context 'when source is not provided' do
    it 'defaults source to round' do
      expect(result.source).to eq('round')
    end

    it 'leaves tournament_id nil' do
      expect(result.tournament_id).to be_nil
    end
  end

  context 'when source is season' do
    subject(:result) do
      described_class.call(
        team_module_id: team_module.id,
        round_ids: [round.id],
        mode: 'top',
        number: 3,
        players: players,
        source: 'season',
        tournament_id: tournament.id
      )
    end

    let(:tournament) { Tournament.first }

    it 'sets source to season' do
      expect(result.source).to eq('season')
    end

    it 'stores tournament_id' do
      expect(result.tournament_id).to eq(tournament.id)
    end

    it 'persists the WeeklyTeam' do
      expect { result }.to change(WeeklyTeam, :count).by(1)
    end
  end

  context 'when source is avg' do
    subject(:result) do
      described_class.call(
        team_module_id: team_module.id,
        round_ids: [round.id],
        mode: 'top',
        number: 4,
        players: players,
        source: 'avg',
        tournament_id: tournament.id
      )
    end

    let(:tournament) { Tournament.first }

    it 'sets source to avg' do
      expect(result.source).to eq('avg')
    end

    it 'stores tournament_id' do
      expect(result.tournament_id).to eq(tournament.id)
    end

    it 'persists the WeeklyTeam' do
      expect { result }.to change(WeeklyTeam, :count).by(1)
    end
  end

  context 'when source is season but tournament_id is missing' do
    subject(:result) do
      described_class.call(
        team_module_id: team_module.id,
        round_ids: [round.id],
        mode: 'top',
        number: 5,
        players: players,
        source: 'season'
      )
    end

    it { is_expected.to be_nil }

    it 'does not create a WeeklyTeam' do
      expect { result }.not_to change(WeeklyTeam, :count)
    end
  end
end
