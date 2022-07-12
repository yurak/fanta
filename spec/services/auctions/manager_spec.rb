RSpec.describe Auctions::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(auction, status) }

    let(:auction) { create(:auction, status: current_status) }
    let(:current_status) { 'initial' }
    let(:status) { 'status' }

    context 'with initial auction' do
      before do
        manager.call
      end

      context 'with invalid status' do
        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with sales status' do
        let(:status) { 'sales' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end

      context 'with blind_bids status' do
        let(:status) { 'blind_bids' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end

      context 'with live status' do
        let(:status) { 'live' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end

      context 'with closed status' do
        let(:status) { 'closed' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end
    end

    context 'with sales auction' do
      let(:current_status) { 'sales' }

      before do
        manager.call
      end

      context 'with invalid status' do
        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with initial status' do
        let(:status) { 'initial' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with blind_bids status' do
        let(:status) { 'blind_bids' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end

      context 'with live status' do
        let(:status) { 'live' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end

      context 'with closed status' do
        let(:status) { 'closed' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end
    end

    context 'with blind_bids auction' do
      let(:current_status) { 'blind_bids' }

      before do
        manager.call
      end

      context 'with invalid status' do
        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with initial status' do
        let(:status) { 'initial' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with sales status' do
        let(:status) { 'sales' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with live status' do
        let(:status) { 'live' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with closed status' do
        let(:status) { 'closed' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end
    end

    context 'with live auction' do
      let(:current_status) { 'live' }

      before do
        manager.call
      end

      context 'with invalid status' do
        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with initial status' do
        let(:status) { 'initial' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with sales status' do
        let(:status) { 'sales' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with blind_bids status' do
        let(:status) { 'blind_bids' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with closed status' do
        let(:status) { 'closed' }

        it 'updates status' do
          expect(auction.reload.status).to eq(status)
        end
      end
    end

    context 'with closed auction' do
      let(:current_status) { 'closed' }

      before do
        manager.call
      end

      context 'with invalid status' do
        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with initial status' do
        let(:status) { 'initial' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with sales status' do
        let(:status) { 'sales' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with blind_bids status' do
        let(:status) { 'blind_bids' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end

      context 'with live status' do
        let(:status) { 'live' }

        it 'does not update status' do
          expect(auction.reload.status).to eq(current_status)
        end
      end
    end
  end
end
