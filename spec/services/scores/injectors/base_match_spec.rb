RSpec.describe Scores::Injectors::BaseMatch do
  let(:concrete_class) do
    Class.new(described_class) do
      def match_finished?
        true
      end

      def host_result
        2
      end

      def guest_result
        1
      end

      def update_round_player(_round_player, _team_hash, _team_missed_goals)
        nil
      end

      def full_player_hash(_round_player, data, _team_missed_goals)
        { score: data[:rating] }
      end
    end
  end

  let(:match) { create(:tournament_match, page_url: '/some/url') }
  let(:injector) { concrete_class.new(match) }

  before { allow(Audit::CsvWriter).to receive(:call) }

  describe '#call' do
    context 'when match has no page_url' do
      before { allow(match).to receive(:page_url).and_return(nil) }

      it { expect(injector.call).to be_nil }

      it 'does not update host score' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end

      it 'does not update guest score' do
        injector.call
        expect(match.reload.guest_score).to be_nil
      end
    end

    context 'when match is not finished' do
      let(:concrete_class) do
        Class.new(described_class) do
          def match_finished?
            false
          end

          def host_result; end
          def guest_result; end
          def update_round_player(_round_player, _team_hash, _team_missed_goals); end
          def full_player_hash(_round_player, _data, _team_missed_goals); end
        end
      end

      it { expect(injector.call).to be_nil }

      it 'does not update host score' do
        injector.call
        expect(match.reload.host_score).to be_nil
      end

      it 'does not update guest score' do
        injector.call
        expect(match.reload.guest_score).to be_nil
      end
    end

    context 'when match is finished' do
      it 'updates host score' do
        injector.call
        expect(match.reload.host_score).to eq(2)
      end

      it 'updates guest score' do
        injector.call
        expect(match.reload.guest_score).to eq(1)
      end

      it 'calls Audit::CsvWriter with merged scores hash' do
        injector.call
        expect(Audit::CsvWriter).to have_received(:call).with(match, {})
      end
    end
  end

  describe '#rating' do
    subject(:rating) { injector.send(:rating, player_data) }

    context 'when rating is nil and player played' do
      let(:player_data) { { rating: nil, played_minutes: 90 } }

      it { is_expected.to eq(described_class::DEFAULT_SCORE) }
    end

    context 'when rating is zero and player played' do
      let(:player_data) { { rating: 0, played_minutes: 75 } }

      it { is_expected.to eq(described_class::DEFAULT_SCORE) }
    end

    context 'when rating is nil and player did not play' do
      let(:player_data) { { rating: nil, played_minutes: 0 } }

      it { is_expected.to eq(0.0) }
    end

    context 'when rating is nil and played_minutes is nil' do
      let(:player_data) { { rating: nil, played_minutes: nil } }

      it { is_expected.to eq(0.0) }
    end

    context 'when rating is present' do
      let(:player_data) { { rating: 7.55 } }

      it { is_expected.to eq(7.6) }
    end

    context 'when rating is an integer' do
      let(:player_data) { { rating: 8 } }

      it { is_expected.to eq(8.0) }
    end
  end

  describe '#cleansheet?' do
    subject(:cleansheet) { injector.send(:cleansheet?, round_player, team_missed_goals, played_minutes) }

    let(:team_missed_goals) { 0 }
    let(:played_minutes) { 90 }

    context 'with a defender (cleansheet zone)' do
      let(:round_player) { create(:round_player, :with_pos_dc) }

      it { is_expected.to be true }

      context 'when played_minutes is below minimum (60)' do
        let(:played_minutes) { 59 }

        it { is_expected.to be false }
      end

      context 'when played_minutes equals minimum (60)' do
        let(:played_minutes) { 60 }

        it { is_expected.to be true }
      end

      context 'when team conceded a goal' do
        let(:team_missed_goals) { 1 }

        it { is_expected.to be false }
      end
    end

    context 'with a goalkeeper' do
      let(:round_player) { create(:round_player, :with_pos_por) }

      it { is_expected.to be true }
    end

    context 'with a defensive midfielder (cleansheet zone)' do
      let(:round_player) { create(:round_player, :with_pos_m) }

      it { is_expected.to be true }
    end

    context 'with a forward (not in cleansheet zone)' do
      let(:round_player) { create(:round_player, :with_pos_pc) }

      it { is_expected.to be false }
    end

    context 'with a winger (not in cleansheet zone)' do
      let(:round_player) { create(:round_player, :with_pos_c) }

      it { is_expected.to be false }
    end
  end

  describe '#missed_goals' do
    subject(:missed_goals) { injector.send(:missed_goals, round_player, 3) }

    context 'with a goalkeeper' do
      let(:round_player) { create(:round_player, :with_pos_por) }

      it { is_expected.to eq(3) }
    end

    context 'with a defender' do
      let(:round_player) { create(:round_player, :with_pos_dc) }

      it { is_expected.to eq(0) }
    end

    context 'with a forward' do
      let(:round_player) { create(:round_player, :with_pos_pc) }

      it { is_expected.to eq(0) }
    end
  end

  describe '#stat_value' do
    subject(:stat_value) { injector.send(:stat_value, player_data, :goals) }

    context 'when key is missing' do
      let(:player_data) { {} }

      it { is_expected.to eq(0) }
    end

    context 'when value is nil' do
      let(:player_data) { { goals: nil } }

      it { is_expected.to eq(0) }
    end

    context 'when value is present' do
      let(:player_data) { { goals: 2 } }

      it { is_expected.to eq(2) }
    end
  end

  describe '#round_player_params' do
    subject(:params) { injector.send(:round_player_params, round_player, player_data, team_missed_goals) }

    let(:round_player) { create(:round_player, :with_pos_dc) }
    let(:player_data) { { rating: 7.0 } }
    let(:team_missed_goals) { 0 }

    context 'when round_player has manual_lock' do
      before { round_player.update(manual_lock: true) }

      it { is_expected.to eq({ score: 7.0, in_squad: true }) }
    end

    context 'when round_player does not have manual_lock' do
      it { is_expected.to eq({ score: 7.0 }) }
    end
  end
end
