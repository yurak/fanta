RSpec.describe Scores::Injectors::SofascoreMatch do
  subject(:injector) { described_class.new(match) }

  let(:finished_event_data) do
    {
      'event' => {
        'status' => { 'type' => 'finished' },
        'hasEventPlayerStatistics' => true,
        'homeScore' => { 'display' => 2 },
        'awayScore' => { 'display' => 1 }
      }
    }.to_json
  end

  let(:lineups_json) do
    {
      'home' => {
        'players' => [
          {
            'player' => { 'id' => 100, 'name' => 'Buffon' },
            'statistics' => { 'minutesPlayed' => 90, 'rating' => 7.5,
                              'goals' => 0, 'goalAssist' => 1, 'ownGoals' => 0, 'saves' => 3 }
          }
        ]
      },
      'away' => {
        'players' => [
          {
            'player' => { 'id' => 200, 'name' => 'Messi' },
            'statistics' => { 'minutesPlayed' => 90, 'rating' => 8.5,
                              'goals' => 1, 'goalAssist' => 0, 'ownGoals' => 0, 'saves' => 0 }
          }
        ]
      }
    }.to_json
  end

  let(:match) do
    create(:tournament_match, page_url: '/sofascore/match', base_data: finished_event_data, lineups_data: lineups_json)
  end

  before { allow(Audit::CsvWriter).to receive(:call) }

  describe '#call' do
    context 'when base_data is blank' do
      let(:match) { create(:tournament_match, base_data: nil, lineups_data: lineups_json) }

      it { expect(injector.call).to be_nil }
    end

    context 'when lineups_data is blank' do
      let(:match) { create(:tournament_match, base_data: finished_event_data, lineups_data: nil) }

      it { expect(injector.call).to be_nil }
    end

    context 'when match is not finished' do
      let(:finished_event_data) do
        { 'event' => { 'status' => { 'type' => 'inprogress' }, 'hasEventPlayerStatistics' => false } }.to_json
      end

      it { expect(injector.call).to be_nil }
    end

    context 'when finished but no player statistics' do
      let(:finished_event_data) do
        { 'event' => { 'status' => { 'type' => 'finished' }, 'hasEventPlayerStatistics' => false } }.to_json
      end

      it { expect(injector.call).to be_nil }
    end

    context 'when match is finished with player statistics' do
      it 'updates host score' do
        injector.call
        expect(match.reload.host_score).to eq(2)
      end

      it 'updates guest score' do
        injector.call
        expect(match.reload.guest_score).to eq(1)
      end

      it 'calls Audit::CsvWriter' do
        injector.call
        expect(Audit::CsvWriter).to have_received(:call)
      end
    end
  end

  describe '#match_finished?' do
    subject { injector.send(:match_finished?) }

    context 'when status is finished and has player stats' do
      it { is_expected.to be true }
    end

    context 'when status is finished but no player stats' do
      let(:finished_event_data) do
        { 'event' => { 'status' => { 'type' => 'finished' }, 'hasEventPlayerStatistics' => false } }.to_json
      end

      it { is_expected.to be false }
    end

    context 'when status is not finished' do
      let(:finished_event_data) do
        { 'event' => { 'status' => { 'type' => 'inprogress' }, 'hasEventPlayerStatistics' => true } }.to_json
      end

      it { is_expected.to be false }
    end

    context 'when event_data is invalid JSON' do
      let(:match) { create(:tournament_match, base_data: 'not-json', lineups_data: lineups_json) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#host_result and #guest_result' do
    it 'reads host score from event_data' do
      expect(injector.send(:host_result)).to eq(2)
    end

    it 'reads guest score from event_data' do
      expect(injector.send(:guest_result)).to eq(1)
    end
  end

  describe '#rating' do
    subject(:result) { injector.send(:rating, player_data) }

    context 'when rating is nil and player played' do
      let(:player_data) { { rating: nil, played_minutes: 90 } }

      it 'returns SofascoreMatch DEFAULT_SCORE (6.5)' do
        expect(result).to eq(6.5)
      end
    end

    context 'when rating is 0 and player played' do
      let(:player_data) { { rating: 0, played_minutes: 60 } }

      it { is_expected.to eq(6.5) }
    end

    context 'when rating is present' do
      let(:player_data) { { rating: 7.55 } }

      it 'rounds to 1 decimal' do
        expect(result).to eq(7.6)
      end
    end
  end

  describe '#build_players_hash' do
    subject(:hash) { injector.send(:build_players_hash, players) }

    context 'with valid players' do
      let(:players) do
        [
          {
            'player' => { 'id' => 101, 'name' => 'Ronaldo' },
            'statistics' => { 'minutesPlayed' => 90, 'rating' => 9.0,
                              'goals' => 2, 'goalAssist' => 0, 'ownGoals' => 0, 'saves' => 0 }
          }
        ]
      end

      it 'keys the hash by sofascore player id' do
        expect(hash.keys).to contain_exactly(101)
      end

      it 'includes rating and goals' do
        expect(hash[101]).to include(rating: 9.0, goals: 2)
      end
    end

    context 'when player has no statistics' do
      let(:players) { [{ 'player' => { 'id' => 101 }, 'statistics' => nil }] }

      it 'skips the player' do
        expect(hash).to be_empty
      end
    end

    context 'when player has 0 minutesPlayed' do
      let(:players) do
        [
          {
            'player' => { 'id' => 101, 'name' => 'Bench' },
            'statistics' => { 'minutesPlayed' => 0, 'rating' => 6.0,
                              'goals' => 0, 'goalAssist' => 0, 'ownGoals' => 0, 'saves' => 0 }
          }
        ]
      end

      it 'skips the player' do
        expect(hash).to be_empty
      end
    end
  end

  describe '#host_scores_hash and #guest_scores_hash' do
    context 'when home lineups_data is present' do
      it 'returns hash with home player data keyed by sofascore id' do
        expect(injector.send(:host_scores_hash)).to have_key(100)
      end
    end

    context 'when away lineups_data is present' do
      it 'returns hash with away player data keyed by sofascore id' do
        expect(injector.send(:guest_scores_hash)).to have_key(200)
      end
    end

    context 'when lineups_data is invalid JSON' do
      let(:match) { create(:tournament_match, base_data: finished_event_data, lineups_data: 'bad-json') }

      it 'returns empty hash for host' do
        expect(injector.send(:host_scores_hash)).to eq({})
      end
    end

    context 'when lineups_data has no home key' do
      let(:lineups_json) { { 'away' => { 'players' => [] } }.to_json }

      it 'returns empty hash for host' do
        expect(injector.send(:host_scores_hash)).to eq({})
      end
    end

    context 'when lineups_data has no away key' do
      let(:lineups_json) { { 'home' => { 'players' => [] } }.to_json }

      it 'returns empty hash for guest' do
        expect(injector.send(:guest_scores_hash)).to eq({})
      end
    end
  end

  describe '#update_round_player' do
    let(:player) { create(:player, sofascore_id: 100) }
    let(:round_player) { create(:round_player, player: player, tournament_round: match.tournament_round) }
    let(:team_hash) { { 100 => { rating: 7.5, played_minutes: 90 } } }

    context 'when player is in the hash' do
      it 'updates round_player' do
        expect do
          injector.send(:update_round_player, round_player, team_hash, 0)
        end.to(change { round_player.reload.updated_at })
      end

      it 'removes player from hash' do
        injector.send(:update_round_player, round_player, team_hash, 0)
        expect(team_hash).not_to have_key(100)
      end
    end

    context 'when player is not in the hash' do
      let(:team_hash) { {} }

      it 'does nothing' do
        expect do
          injector.send(:update_round_player, round_player, team_hash, 0)
        end.not_to(change { round_player.reload.score })
      end
    end
  end

  describe '#full_player_hash' do
    subject(:hash) { injector.send(:full_player_hash, round_player, player_data, 0) }

    let(:round_player) { create(:round_player, :with_pos_por) }
    let(:player_data) { { rating: 7.0, played_minutes: 90, goals: 0, assists: 1, own_goals: 0, saves: 4 } }

    it 'includes score, goals, assists, saves and played_minutes' do
      expect(hash).to include(score: 7.0, goals: 0, assists: 1, saves: 4, played_minutes: 90)
    end

    it 'includes cleansheet for goalkeeper with no goals conceded' do
      expect(hash[:cleansheet]).to be true
    end

    it 'includes missed_goals (goalkeeper gets team count)' do
      hash_with_goals = injector.send(:full_player_hash, round_player, player_data, 2)
      expect(hash_with_goals[:missed_goals]).to eq(2)
    end
  end
end
