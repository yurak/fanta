require 'rails_helper'

RSpec.describe Players::Transfermarkt::Parser do
  describe '#call' do
    subject(:parser) { described_class.new(tm_id) }

    before do
      create(:season, start_year: 2023, end_year: 2024)
    end

    let(:tm_id) { '569598' }

    context 'without tm_id' do
      let(:tm_id) { nil }

      it { expect(parser.call).to be(false) }
    end

    context 'with player full data' do
      let(:club) { create(:club, name: 'Milan', tm_name: 'AC Milan') }
      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html') }

      before do
        club
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(fofana_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return(%w[DM CM])
      end

      it 'returns player first name' do
        expect(parser.call[:first_name]).to eq('Youssouf')
      end

      it 'returns player last name' do
        expect(parser.call[:name]).to eq('Fofana')
      end

      it 'returns player country code' do
        expect(parser.call[:nationality]).to eq('fr')
      end

      it 'returns player club id' do
        expect(parser.call[:club_id]).to eq(club.id)
      end

      it 'returns player club name' do
        expect(parser.call[:club_name]).to eq(club.name)
      end

      it 'returns player price' do
        expect(parser.call[:tm_price]).to eq(28_000_000)
      end

      it 'returns player height' do
        expect(parser.call[:height]).to eq(185)
      end

      it 'returns player number' do
        expect(parser.call[:number]).to eq(19)
      end

      it 'returns player birth date' do
        expect(parser.call[:birth_date]).to eq('10/01/1999')
      end

      it 'returns player main position' do
        expect(parser.call[:position1]).to eq('M')
      end

      it 'returns player second position' do
        expect(parser.call[:position2]).to eq('C')
      end

      it 'returns player third position' do
        expect(parser.call[:position3]).to be_nil
      end
    end

    context 'with position_skip: true' do
      subject(:parser) { described_class.new(tm_id, position_skip: true) }

      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html') }

      before do
        create(:club, name: 'Milan', tm_name: 'AC Milan')
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(fofana_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call)
      end

      it 'skips PositionMapper' do
        parser.call
        expect(Players::Transfermarkt::PositionMapper).not_to have_received(:call)
      end

      it 'returns nil for position1' do
        expect(parser.call[:position1]).to be_nil
      end

      it 'returns nil for position2' do
        expect(parser.call[:position2]).to be_nil
      end

      it 'returns nil for position3' do
        expect(parser.call[:position3]).to be_nil
      end
    end

    context 'when club is not found' do
      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html') }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(fofana_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return([])
      end

      it 'returns nil club_id' do
        expect(parser.call[:club_id]).to be_nil
      end

      it 'returns nil club_name' do
        expect(parser.call[:club_name]).to be_nil
      end
    end

    context 'when PositionMapper returns three positions' do
      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html') }

      before do
        create(:club, name: 'Milan', tm_name: 'AC Milan')
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(fofana_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return(%w[DM CM WB])
      end

      it 'returns third position' do
        expect(parser.call[:position3]).to eq(Position::WING_BACK)
      end
    end

    context 'when PositionMapper returns empty due to insufficient stats' do
      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html').read }

      before do
        create(:club, name: 'Milan', tm_name: 'AC Milan')
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(fofana_html)
        allow(Players::Transfermarkt::PositionParser).to receive(:call).and_return({})
      end

      it 'falls back to primary TM base position for position1' do
        expect(parser.call[:position1]).to eq('M')
      end

      it 'returns nil for position2 when primary is not a fullback' do
        expect(parser.call[:position2]).to be_nil
      end
    end

    context 'when BrowserClient raises CaptchaRequired' do
      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient)
          .to receive(:fetch_html)
          .and_raise(Players::Transfermarkt::CaptchaRequired)
      end

      it 'propagates the error' do
        expect { parser.call }.to raise_error(Players::Transfermarkt::CaptchaRequired)
      end
    end

    context 'when info_box_details is blank (no info-box in HTML)' do
      let(:minimal_html) do
        '<html><body><div class="data-header__headline-wrapper"><span>John</span><span>Doe</span></div></body></html>'
      end

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(minimal_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return([])
      end

      it 'returns nil for birth_date' do
        expect(parser.call[:birth_date]).to be_nil
      end

      it 'returns nil for height' do
        expect(parser.call[:height]).to be_nil
      end
    end

    context 'with chip player full data' do
      let(:tm_id) { '939745' }

      let(:torriani_html) do
        Rails.root.join('spec/fixtures/tm/player_939745.html').read
      end

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(torriani_html)
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return([])
      end

      it 'returns player price in thousands' do
        expect(parser.call[:tm_price]).to eq(500_000)
      end
    end
  end
end
