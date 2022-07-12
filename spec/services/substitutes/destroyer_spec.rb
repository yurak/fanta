RSpec.describe Substitutes::Destroyer do
  describe '#call' do
    subject(:destroyer) { described_class.new(subs_id) }

    let(:substitute) { create(:substitute) }
    let(:subs_id) { substitute.id }

    context 'without existing substitute' do
      let(:subs_id) { '' }

      it { expect(destroyer.call).to be(false) }
    end

    context 'with valid params' do
      let(:in_rp) { substitute.in_rp }
      let(:reserve_rp) { substitute.out_rp }

      before do
        destroyer.call
      end

      it 'updates round_player of main match_player' do
        expect(substitute.main_mp.reload.round_player).to eq(substitute.out_rp)
      end

      it 'updates subs_status of main match_player' do
        expect(substitute.main_mp.reload.subs_status).to eq('initial')
      end

      it 'updates round_player of reserve match_player' do
        expect(substitute.reserve_mp.reload.round_player).to eq(substitute.in_rp)
      end

      it 'updates subs_status of reserve match_player' do
        expect(substitute.reserve_mp.reload.subs_status).to eq('initial')
      end

      it 'returns substitute' do
        expect(destroyer.call).to eq(substitute)
      end

      it 'destroys substitute' do
        expect(Substitute.find_by(id: substitute.id)).to be_nil
      end
    end
  end
end
