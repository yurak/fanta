RSpec.describe Scores::Injectors::FotmobMatch do
  let(:match) { create(:tournament_match, page_url: '/matches/inter-vs-arsenal/2tgrh0#4621502') }
  let(:injector) { described_class.new(match) }
  let(:finished_status) do
    { 'started' => true, 'finished' => true, 'awarded' => false, 'scoreStr' => '2 - 1' }
  end
  let(:match_data) do
    {
      'general' => { 'leagueRoundName' => match.tournament_round.number.to_s },
      'header' => { 'status' => finished_status },
      'content' => {}
    }
  end

  before do
    allow(injector).to receive(:match_data).and_return(match_data)
    allow(Audit::CsvWriter).to receive(:call)
    allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return({})
  end

  describe '#call' do
    context 'when match is finished' do
      it 'updates host score' do
        injector.call
        expect(match.reload.host_score).to eq(2)
      end

      it 'updates guest score' do
        injector.call
        expect(match.reload.guest_score).to eq(1)
      end

      it 'calls Audit::CsvWriter with players_hash' do
        players = { 123 => { rating: 7.5 } }
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(players)
        injector.call
        expect(Audit::CsvWriter).to have_received(:call).with(match, players)
      end
    end

    context 'when match is not finished' do
      let(:finished_status) { { 'started' => true, 'finished' => false, 'awarded' => false } }

      it { expect(injector.call).to be_nil }

      it 'does not update scores' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end
    end

    context 'when fetched data belongs to a different round (e.g. Cup instead of league)' do
      let(:match_data) do
        {
          'general' => { 'leagueRoundName' => (match.tournament_round.number + 1).to_s },
          'header' => { 'status' => finished_status },
          'content' => {}
        }
      end

      it { expect(injector.call).to be_nil }

      it 'does not update scores' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end
    end

    context 'when tournament has skip_round_check enabled' do
      let(:wrong_round_data) do
        {
          'general' => { 'leagueRoundName' => 'Regular Season' },
          'header' => { 'status' => finished_status },
          'content' => {}
        }
      end

      before do
        match.tournament_round.tournament.update!(skip_round_check: true)
        allow(injector).to receive(:match_data).and_return(wrong_round_data)
      end

      it 'updates host score' do
        injector.call
        expect(match.reload.host_score).to eq(2)
      end

      it 'updates guest score' do
        injector.call
        expect(match.reload.guest_score).to eq(1)
      end
    end
  end

  describe '#correct_round?' do
    subject { injector.send(:correct_round?) }

    context 'when fetched round matches tournament round number' do
      it { is_expected.to be true }
    end

    context 'when fetched round does not match' do
      let(:match_data) do
        {
          'general' => { 'leagueRoundName' => (match.tournament_round.number + 5).to_s },
          'header' => { 'status' => finished_status },
          'content' => {}
        }
      end

      it { is_expected.to be false }
    end

    context 'when leagueRoundName is missing from match_data' do
      let(:match_data) { { 'header' => { 'status' => finished_status }, 'content' => {} } }

      it { is_expected.to be false }
    end

    context 'when tournament has skip_round_check enabled' do
      before { match.tournament_round.tournament.update!(skip_round_check: true) }

      it { is_expected.to be true }
    end
  end

  describe '#match_finished?' do
    subject { injector.send(:match_finished?) }

    context 'when started and finished' do
      it { is_expected.to be true }
    end

    context 'when awarded and finished' do
      let(:finished_status) { { 'started' => false, 'awarded' => true, 'finished' => true, 'scoreStr' => '3 - 0' } }

      it { is_expected.to be true }
    end

    context 'when started but not finished' do
      let(:finished_status) { { 'started' => true, 'finished' => false, 'awarded' => false } }

      it { is_expected.to be false }
    end

    context 'when neither started nor awarded' do
      let(:finished_status) { { 'started' => false, 'awarded' => false, 'finished' => false } }

      it { is_expected.to be_falsy }
    end

    context 'when header is missing from match_data' do
      let(:match_data) { {} }

      it { is_expected.to be_falsy }
    end
  end

  describe '#players_hash' do
    it 'returns the result of FotmobPlayersData' do
      players = { 99 => { rating: 8.0 } }
      allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(players)
      expect(injector.send(:players_hash)).to eq(players)
    end
  end

  describe '#host_result and #guest_result' do
    it 'parses host score from scoreStr' do
      expect(injector.send(:host_result)).to eq('2')
    end

    it 'parses guest score from scoreStr' do
      expect(injector.send(:guest_result)).to eq('1')
    end
  end

  describe '#conceded_penalty' do
    subject(:result) { injector.send(:conceded_penalty, player_data) }

    context 'when penalty_missed_goals is positive' do
      let(:player_data) { { conceded_penalty: 0, penalty_missed_goals: 1 } }

      it 'uses penalty_missed_goals' do
        expect(result).to eq(1)
      end
    end

    context 'when penalty_missed_goals is zero' do
      let(:player_data) { { conceded_penalty: 2, penalty_missed_goals: 0 } }

      it 'uses conceded_penalty' do
        expect(result).to eq(2)
      end
    end

    context 'when penalty_missed_goals is nil' do
      let(:player_data) { { conceded_penalty: 1 } }

      it 'uses conceded_penalty' do
        expect(result).to eq(1)
      end
    end

    context 'when both are absent' do
      let(:player_data) { {} }

      it { is_expected.to eq(0) }
    end
  end

  describe '#full_player_hash' do
    subject(:hash) { injector.send(:full_player_hash, round_player, player_data, 0) }

    let(:round_player) { create(:round_player, :with_pos_dc) }
    let(:player_data) do
      {
        rating: 7.5, played_minutes: 90, goals: 1, assists: 0,
        scored_penalty: 0, caught_penalty: 0, failed_penalty: 0,
        missed_goals: 0, own_goals: 0, saves: 0,
        yellow_card: nil, red_card: nil, conceded_penalty: 0, penalties_won: 0
      }
    end

    it { expect(hash).to include(score: 7.5, goals: 1, assists: 0, played_minutes: 90) }

    it 'includes cleansheet for defender with no goals conceded' do
      expect(hash[:cleansheet]).to be true
    end

    it 'includes conceded_penalty key' do
      expect(hash).to have_key(:conceded_penalty)
    end
  end

  describe '#update_round_player' do
    let(:player) { create(:player, fotmob_id: 99_001) }
    let(:round_player) { create(:round_player, player: player, tournament_round: match.tournament_round) }
    let(:team_hash) { { 99_001 => { rating: 7.5, played_minutes: 90 } } }

    context 'when player is in the hash' do
      it 'updates round_player' do
        expect do
          injector.send(:update_round_player, round_player, team_hash, 0)
        end.to(change { round_player.reload.updated_at })
      end

      it 'removes player from hash to prevent duplicate processing' do
        injector.send(:update_round_player, round_player, team_hash, 0)
        expect(team_hash).not_to have_key(99_001)
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
end
