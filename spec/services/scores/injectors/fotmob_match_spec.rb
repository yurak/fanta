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
      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
          123 => { rating: 7.5, played_minutes: 90 }
        )
      end

      it 'updates host score' do
        injector.call
        expect(match.reload.host_score).to eq(2)
      end

      it 'updates guest score' do
        injector.call
        expect(match.reload.guest_score).to eq(1)
      end

      it 'calls Audit::CsvWriter with players_hash' do
        players = { 123 => { rating: 7.5, played_minutes: 90 } }
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(players)
        injector.call
        expect(Audit::CsvWriter).to have_received(:call).with(match, players)
      end
    end

    context 'when match is finished but players data is not ready (all played_minutes are zero)' do
      before do
        players = {
          101 => { rating: 7.5, played_minutes: 0 },
          102 => { rating: 6.0, played_minutes: 0 }
        }
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(players)
      end

      it 'does not update scores' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end

      it 'does not call Audit::CsvWriter' do
        injector.call
        expect(Audit::CsvWriter).not_to have_received(:call)
      end
    end

    context 'when match is not finished' do
      let(:finished_status) { { 'started' => true, 'finished' => false, 'awarded' => false } }

      it 'does not update scores' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end
    end

    context 'when run_mode is :live and the match is in progress' do
      let(:injector) { described_class.new(match, run_mode: :live) }
      let(:finished_status) do
        { 'started' => true, 'finished' => false, 'awarded' => false, 'scoreStr' => '1 - 0',
          'liveTime' => { 'short' => "30'" } }
      end

      before do
        # FotMob withholds played_minutes during a live match (0 for everyone) but streams ratings
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(123 => { rating: 7.2, played_minutes: 0 })
      end

      it 'updates the live score' do
        injector.call
        expect(match.reload.host_score).to eq(1)
      end

      it 'marks the match as live' do
        injector.call
        expect(match.reload).to be_live
      end

      it 'stores the live minute' do
        injector.call
        expect(match.reload.live_minute).to eq(30)
      end

      it 'does not run the missed-players audit while in progress' do
        injector.call
        expect(Audit::CsvWriter).not_to have_received(:call)
      end
    end

    context 'when run_mode is :live, in progress, but no ratings are available yet' do
      let(:injector) { described_class.new(match, run_mode: :live) }
      let(:finished_status) do
        { 'started' => true, 'finished' => false, 'awarded' => false, 'scoreStr' => '1 - 0',
          'liveTime' => { 'short' => "5'" } }
      end

      before do
        # early minutes: FotMob has a scoreline but no ratings yet
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(123 => { rating: 0, played_minutes: 0 })
      end

      it 'still writes the provisional live score' do
        injector.call
        expect(match.reload.host_score).to eq(1)
      end

      it 'marks the match as live' do
        injector.call
        expect(match.reload).to be_live
      end

      it 'stores the live minute' do
        injector.call
        expect(match.reload.live_minute).to eq(5)
      end

      it 'does not run the audit' do
        injector.call
        expect(Audit::CsvWriter).not_to have_received(:call)
      end
    end

    context 'when run_mode is :live and the match is finished' do
      let(:injector) { described_class.new(match, run_mode: :live) }

      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(123 => { rating: 7.5, played_minutes: 90 })
      end

      it 'marks the match as finished' do
        injector.call
        expect(match.reload).to be_finished
      end

      it 'clears the live minute at full time' do
        match.update!(live_minute: 45)
        injector.call
        expect(match.reload.live_minute).to be_nil
      end

      it 'runs the missed-players audit at full time' do
        injector.call
        expect(Audit::CsvWriter).to have_received(:call)
      end
    end

    context 'when run_mode is :schedule' do
      let(:injector) { described_class.new(match, run_mode: :schedule) }
      let(:finished_status) do
        { 'started' => false, 'finished' => false, 'utcTime' => '2027-01-16T14:30:00.000Z', 'matchDateTbd' => false }
      end

      it 'refreshes the kickoff date' do
        injector.call
        expect(match.reload.date).to eq('JAN 16, 2027')
      end

      it 'refreshes the kickoff time' do
        injector.call
        expect(match.reload.time).to eq('14:30')
      end

      it 'does not write scores' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end

      it 'does not run the audit' do
        injector.call
        expect(Audit::CsvWriter).not_to have_received(:call)
      end

      context 'when the kickoff time is still TBD' do
        let(:finished_status) do
          { 'started' => false, 'finished' => false, 'utcTime' => '2027-01-16T14:30:00.000Z', 'matchDateTbd' => true }
        end

        it 'leaves the stored date untouched' do
          match.update!(date: 'OLD', time: '00:00')
          injector.call
          expect(match.reload.date).to eq('OLD')
        end
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
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
          123 => { rating: 7.5, played_minutes: 90 }
        )
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

  describe '#players_data_ready?' do
    subject { injector.send(:players_data_ready?) }

    context 'when at least one player has played_minutes > 0' do
      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
          101 => { rating: 7.5, played_minutes: 90 },
          102 => { rating: 6.0, played_minutes: 0 }
        )
      end

      it { is_expected.to be true }
    end

    context 'when all players have played_minutes = 0' do
      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
          101 => { rating: 7.5, played_minutes: 0 },
          102 => { rating: 6.0, played_minutes: 0 }
        )
      end

      it { is_expected.to be false }
    end

    context 'when players_hash is empty' do
      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return({})
      end

      it { is_expected.to be false }
    end

    context 'when run_mode is :live' do
      let(:injector) { described_class.new(match, run_mode: :live) }

      context 'when a player has a rating but no minutes yet (live match)' do
        before do
          allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
            101 => { rating: 7.2, played_minutes: 0 }
          )
        end

        it { is_expected.to be true }
      end

      context 'when no player has a positive rating' do
        before do
          allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
            101 => { rating: 0, played_minutes: 0 }
          )
        end

        it { is_expected.to be false }
      end
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

  describe '#missed_penalty' do
    subject(:result) { injector.send(:missed_penalty, round_player, player_data, penalty_minutes) }

    let(:round_player) { create(:round_player, :with_pos_por) }
    let(:player_data) { { missed_goals: 1 } }
    let(:penalty_minutes) { [55] }

    it 'counts a penalty conceded while the keeper was on the pitch' do
      expect(result).to eq(1)
    end

    context 'when the keeper came on after the penalty' do
      let(:player_data) { { missed_goals: 1, sub_in_minute: 70 } }

      it { is_expected.to eq(0) }
    end

    context 'when the keeper went off before the penalty' do
      let(:player_data) { { missed_goals: 1, sub_out_minute: 40 } }

      it { is_expected.to eq(0) }
    end

    context 'when the player is not a keeper' do
      let(:round_player) { create(:round_player, :with_pos_dc) }

      it { is_expected.to eq(0) }
    end

    context 'when FotMob reports the stat directly' do
      let(:player_data) { { penalty_missed_goals: 2 } }
      let(:penalty_minutes) { [] }

      it { is_expected.to eq(2) }
    end

    context 'when the keeper conceded nothing (sent off before the penalty)' do
      let(:player_data) { { missed_goals: 0 } }

      it { is_expected.to eq(0) }
    end

    context 'with more penalties in the window than goals conceded' do
      let(:player_data) { { missed_goals: 1 } }
      let(:penalty_minutes) { [30, 60] }

      it 'never reports more than he actually conceded' do
        expect(result).to eq(1)
      end
    end

    context 'without penalties in the match' do
      let(:penalty_minutes) { [] }

      it { is_expected.to eq(0) }
    end
  end

  describe '#full_player_hash penalty split for a keeper' do
    subject(:hash) { injector.send(:full_player_hash, round_player, player_data, conceded) }

    let(:round_player) { create(:round_player, :with_pos_por) }
    let(:player_data) { { rating: 6.0, played_minutes: 90, missed_goals: 3, conceded_penalty: 1 } }
    let(:conceded) { { total: 3, minutes: [10, 40, 88], penalty_minutes: [88] } }

    it 'records the penalty goal as missed_penalty' do
      expect(hash[:missed_penalty]).to eq(1)
    end

    it 'drops the penalty goal from missed_goals' do
      expect(hash[:missed_goals]).to eq(2)
    end

    it 'keeps conceded_penalty as the foul stat' do
      expect(hash[:conceded_penalty]).to eq(1)
    end

    context 'without penalties among the conceded goals' do
      let(:conceded) { { total: 3, minutes: [10, 40, 88], penalty_minutes: [] } }

      it 'leaves missed_goals untouched' do
        expect(hash[:missed_goals]).to eq(3)
      end

      it 'records no missed_penalty' do
        expect(hash[:missed_penalty]).to eq(0)
      end
    end
  end

  describe '#full_player_hash' do
    subject(:hash) { injector.send(:full_player_hash, round_player, player_data, conceded) }

    let(:conceded) { { total: 0, minutes: [], penalty_minutes: [] } }

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

    it 'marks player as in_squad' do
      expect(hash[:in_squad]).to be true
    end

    context 'when in live mode' do
      let(:injector) { described_class.new(match, run_mode: :live) }

      it 'forces played_minutes to 0' do
        expect(hash[:played_minutes]).to eq(0)
      end

      it 'defers the cleansheet (minutes below the threshold)' do
        expect(hash[:cleansheet]).to be false
      end
    end
  end

  describe '#full_player_hash cleansheet timing for a subbed-off defender' do
    subject(:cleansheet) do
      injector.send(:full_player_hash, round_player, player_data,
                    { total: 1, minutes: conceded_minutes, penalty_minutes: [] })[:cleansheet]
    end

    let(:round_player) { create(:round_player, :with_pos_dc) }
    let(:player_data) { { rating: 7.0, played_minutes: 70, sub_out_minute: 70, goals: 0, assists: 0 } }
    let(:conceded_minutes) { [75] }

    it 'awards the cleansheet when the goal fell after he left the pitch' do
      expect(cleansheet).to be true
    end

    context 'when the goal was conceded while he was on the pitch' do
      let(:conceded_minutes) { [65] }

      it 'does not award the cleansheet' do
        expect(cleansheet).to be false
      end
    end
  end

  describe '#goal_minutes_conceded_by' do
    let(:match_data) do
      {
        'general' => { 'leagueRoundName' => match.tournament_round.number.to_s },
        'header' => { 'status' => finished_status },
        'content' => { 'matchFacts' => { 'events' => { 'events' => events } } }
      }
    end
    let(:events) do
      [
        { 'type' => 'Goal', 'time' => 20, 'overloadTime' => nil, 'isHome' => true, 'isPenaltyShootoutEvent' => false },
        { 'type' => 'Goal', 'time' => 90, 'overloadTime' => 3, 'isHome' => false, 'isPenaltyShootoutEvent' => false },
        { 'type' => 'Goal', 'time' => 50, 'isHome' => false, 'isPenaltyShootoutEvent' => true },
        { 'type' => 'Substitution', 'time' => 70, 'overloadTime' => 0, 'isHome' => true }
      ]
    end

    it 'collects the minutes the host conceded (goals scored by the guest)' do
      expect(injector.send(:goal_minutes_conceded_by, home: true)).to eq([93])
    end

    it 'collects the minutes the guest conceded (goals scored by the host)' do
      expect(injector.send(:goal_minutes_conceded_by, home: false)).to eq([20])
    end

    it 'ignores penalty shootout goals' do
      expect(injector.send(:goal_minutes_conceded_by, home: true)).not_to include(50)
    end
  end

  describe '#update_round_player' do
    let(:player) { create(:player, fotmob_id: 99_001) }
    let(:round_player) { create(:round_player, player: player, tournament_round: match.tournament_round) }

    before do
      allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return(
        99_001 => { rating: 7.5, played_minutes: 90 }
      )
    end

    context 'when player is in the hash' do
      it 'updates round_player' do
        expect do
          injector.send(:update_round_player, round_player, { total: 0, minutes: [], penalty_minutes: [] })
        end.to(change { round_player.reload.updated_at })
      end

      it 'marks player as in_squad' do
        injector.send(:update_round_player, round_player, { total: 0, minutes: [], penalty_minutes: [] })
        expect(round_player.reload.in_squad).to be true
      end

      it 'removes player from hash to prevent duplicate processing' do
        injector.send(:update_round_player, round_player, { total: 0, minutes: [], penalty_minutes: [] })
        expect(injector.send(:players_hash)).not_to have_key(99_001)
      end
    end

    context 'when player is not in the hash' do
      before do
        allow(Scores::Injectors::FotmobPlayersData).to receive(:call).and_return({})
      end

      it 'does nothing' do
        expect do
          injector.send(:update_round_player, round_player, { total: 0, minutes: [], penalty_minutes: [] })
        end.not_to(change { round_player.reload.score })
      end
    end
  end

  describe 'scrape resilience' do
    # a fresh instance whose #match_data is NOT stubbed, so the real fetch path runs
    let(:live_injector) { described_class.new(match) }

    it 'returns {} when FotMob blocks the request' do
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden)

      expect(live_injector.send(:match_data)).to eq({})
    end

    it 'returns {} when the page has no parseable data' do
      allow(RestClient::Request).to receive(:execute).and_return('<html>blocked</html>')

      expect(live_injector.send(:match_data)).to eq({})
    end

    it 'keeps the stored score instead of blanking it on a block' do
      match.update!(host_score: 2, guest_score: 1)
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden)

      live_injector.call

      expect(match.reload.host_score).to eq(2)
    end
  end

  describe 'retry budget' do
    let(:budget) { Scores::ScrapeBudget.new(limit: 30) }
    let(:budget_injector) { described_class.new(match, budget: budget) }

    before do
      allow(budget_injector).to receive(:sleep)
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::InternalServerError.new(nil, 500))
    end

    it 'retries a 5xx while the budget lasts' do
      budget_injector.send(:match_data)

      expect(RestClient::Request).to have_received(:execute).exactly(3).times
    end

    it 'spends the budget on the backoff' do
      budget_injector.send(:match_data)

      expect(budget.spent).to eq(15)
    end

    context 'when the budget is already spent' do
      before { budget.take(30) }

      it 'gives up after the first attempt' do
        budget_injector.send(:match_data)

        expect(RestClient::Request).to have_received(:execute).once
      end

      it 'still reports a health failure' do
        budget_injector.send(:match_data)

        expect(budget_injector).to be_scrape_health_failure
      end
    end

    context 'with a non-retriable response' do
      before { allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden) }

      it 'does not spend the budget' do
        budget_injector.send(:match_data)

        expect(budget.spent).to eq(0)
      end
    end
  end

  describe '#scrape_health_failure?' do
    let(:live_injector) { described_class.new(match) }

    it 'is true when FotMob blocks the request (403)' do
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden)
      live_injector.send(:match_data)

      expect(live_injector.scrape_health_failure?).to be true
    end

    it 'is true when the page has no parseable data' do
      allow(RestClient::Request).to receive(:execute).and_return('<html>blocked</html>')
      live_injector.send(:match_data)

      expect(live_injector.scrape_health_failure?).to be true
    end

    it 'is false for a stale page_url (404)' do
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::ResourceNotFound)
      live_injector.send(:match_data)

      expect(live_injector.scrape_health_failure?).to be false
    end

    it 'is false when the page was fetched successfully' do
      allow(live_injector).to receive(:match_data).and_return({ 'header' => {} })

      expect(live_injector.scrape_health_failure?).to be false
    end
  end
end
