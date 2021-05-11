RSpec.describe Results::Updater do
  describe '#call' do
    subject(:updater) { described_class.new(tour) }

    let(:tour) { create(:closed_tour) }

    context 'with blank tour' do
      let(:tour) { nil }

      it { expect(updater.call).to eq(false) }
    end

    context 'with not closed tour' do
      let(:tour) { create(:tour) }

      it { expect(updater.call).to eq(false) }
    end

    context 'when tour without matches' do
      it { expect(updater.call).to eq(false) }
    end

    context 'when tour with matches and host team win' do
      let!(:match1) { create(:match, tour: tour) }
      let!(:host_result) { create(:result, team: match1.host, league: tour.league) }
      let!(:guest_result) { create(:result, team: match1.guest, league: tour.league) }
      let!(:lineups) do
        [
          create(:lineup, :with_team_and_score_seven, tour: tour, team: match1.host),
          create(:lineup, :with_team_and_score_six, tour: tour, team: match1.guest)
        ]
      end

      before do
        updater.call
      end

      it 'match has host lineup' do
        expect(match1.host_lineup).to eq(lineups.first)
      end

      it 'match has guest lineup' do
        expect(match1.guest_lineup).to eq(lineups.last)
      end

      it 'updates host team result points' do
        expect(host_result.reload.points).to eq(3)
      end

      it 'updates host team result wins' do
        expect(host_result.reload.wins).to eq(1)
      end

      it 'does not update host team result loses' do
        expect(host_result.reload.loses).to eq(0)
      end

      it 'does not update host team result draws' do
        expect(host_result.reload.draws).to eq(0)
      end

      it 'updates host team result scored goals' do
        expect(host_result.reload.scored_goals).to eq(3)
      end

      it 'updates host team result missed goals' do
        expect(host_result.reload.missed_goals).to eq(1)
      end

      it 'does not update guest team result points' do
        expect(guest_result.reload.points).to eq(0)
      end

      it 'updates guest team result loses' do
        expect(guest_result.reload.loses).to eq(1)
      end

      it 'does not update guest team result wins' do
        expect(guest_result.reload.wins).to eq(0)
      end

      it 'does not update guest team result draws' do
        expect(guest_result.reload.draws).to eq(0)
      end

      it 'updates guest team result scored goals' do
        expect(guest_result.reload.scored_goals).to eq(1)
      end

      it 'updates guest team result missed goals' do
        expect(guest_result.reload.missed_goals).to eq(3)
      end
    end

    context 'when tour with matches and host team lose' do
      let!(:match1) { create(:match, tour: tour) }
      let!(:host_result) { create(:result, team: match1.host, league: tour.league) }
      let!(:guest_result) { create(:result, team: match1.guest, league: tour.league) }
      let!(:lineups) do
        [
          create(:lineup, :with_team_and_score_six, tour: tour, team: match1.host),
          create(:lineup, :with_team_and_score_seven, tour: tour, team: match1.guest)
        ]
      end

      before do
        updater.call
      end

      it 'match has host lineup' do
        expect(match1.host_lineup).to eq(lineups.first)
      end

      it 'match has guest lineup' do
        expect(match1.guest_lineup).to eq(lineups.last)
      end

      it 'does not update host team result points' do
        expect(host_result.reload.points).to eq(0)
      end

      it 'does not update host team result wins' do
        expect(host_result.reload.wins).to eq(0)
      end

      it 'updates host team result loses' do
        expect(host_result.reload.loses).to eq(1)
      end

      it 'does not update host team result draws' do
        expect(host_result.reload.draws).to eq(0)
      end

      it 'updates host team result scored goals' do
        expect(host_result.reload.scored_goals).to eq(1)
      end

      it 'updates host team result missed goals' do
        expect(host_result.reload.missed_goals).to eq(3)
      end

      it 'updates guest team result points' do
        expect(guest_result.reload.points).to eq(3)
      end

      it 'updates guest team result wins' do
        expect(guest_result.reload.wins).to eq(1)
      end

      it 'does not update guest team result loses' do
        expect(guest_result.reload.loses).to eq(0)
      end

      it 'does not update guest team result draws' do
        expect(guest_result.reload.draws).to eq(0)
      end

      it 'updates guest team result scored goals' do
        expect(guest_result.reload.scored_goals).to eq(3)
      end

      it 'updates guest team result missed goals' do
        expect(guest_result.reload.missed_goals).to eq(1)
      end
    end

    context 'when tour with draw match' do
      let!(:match1) { create(:match, tour: tour) }
      let!(:host_result) { create(:result, team: match1.host, league: tour.league) }
      let!(:guest_result) { create(:result, team: match1.guest, league: tour.league) }
      let!(:lineups) do
        [
          create(:lineup, :with_team_and_score_seven, tour: tour, team: match1.host),
          create(:lineup, :with_team_and_score_seven, tour: tour, team: match1.guest)
        ]
      end

      before do
        updater.call
      end

      it 'match has host lineup' do
        expect(match1.host_lineup).to eq(lineups.first)
      end

      it 'match has guest lineup' do
        expect(match1.guest_lineup).to eq(lineups.last)
      end

      it 'updates host team result points' do
        expect(host_result.reload.points).to eq(1)
      end

      it 'does not update host team result wins' do
        expect(host_result.reload.wins).to eq(0)
      end

      it 'does not update host team result loses' do
        expect(host_result.reload.loses).to eq(0)
      end

      it 'updates host team result draws' do
        expect(host_result.reload.draws).to eq(1)
      end

      it 'updates host team result scored goals' do
        expect(host_result.reload.scored_goals).to eq(3)
      end

      it 'updates host team result missed goals' do
        expect(host_result.reload.missed_goals).to eq(3)
      end

      it 'updates guest team result points' do
        expect(guest_result.reload.points).to eq(1)
      end

      it 'does not update guest team result loses' do
        expect(guest_result.reload.loses).to eq(0)
      end

      it 'does not update guest team result wins' do
        expect(guest_result.reload.wins).to eq(0)
      end

      it 'updates guest team result draws' do
        expect(guest_result.reload.draws).to eq(1)
      end

      it 'updates guest team result scored goals' do
        expect(guest_result.reload.scored_goals).to eq(3)
      end

      it 'updates guest team result missed goals' do
        expect(guest_result.reload.missed_goals).to eq(3)
      end
    end
  end
end
