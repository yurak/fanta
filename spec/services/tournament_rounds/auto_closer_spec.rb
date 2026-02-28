RSpec.describe TournamentRounds::AutoCloser do
  describe '#call' do
    subject(:auto_closer) { described_class.new(tournament_round_id) }

    context 'with invalid tournament_round_id' do
      let(:tournament_round_id) { 'invalid' }

      it { expect(auto_closer.call).to be(false) }
    end

    context 'with valid tournament_round_id' do
      let(:tournament_round) { create(:tournament_round) }
      let(:tournament_round_id) { tournament_round.id }

      before { allow(Notifications::Creator).to receive(:call) }

      it 'sets moderated_at' do
        freeze_time do
          auto_closer.call
          expect(tournament_round.reload.moderated_at).to eq(Time.zone.now)
        end
      end

      context 'without tours' do
        it 'does not call Notifications::Creator' do
          auto_closer.call
          expect(Notifications::Creator).not_to have_received(:call)
        end
      end

      context 'with tours' do
        let!(:tours) { create_list(:tour, 2, tournament_round: tournament_round) }

        it 'calls Notifications::Creator for each tour' do
          auto_closer.call
          tours.each do |tour|
            expect(Notifications::Creator).to have_received(:call).with(notifiable: tour, kind: :tour_moderated)
          end
        end
      end
    end
  end
end
