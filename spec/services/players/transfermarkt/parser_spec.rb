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
      let!(:club) { create(:club, name: 'Milan', tm_name: 'AC Milan') }
      let(:fofana_html) { Rails.root.join('spec/fixtures/tm/player_569598.html') }
      let(:positions_html) { Rails.root.join('spec/fixtures/tm/positions_569598_2023.html') }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do |_client, url, **_opts|
          url = url.to_s

          if url.include?('/profil/spieler/')
            fofana_html
          elsif url.include?('/leistungsdaten/') || url.include?('performance')
            positions_html
          else
            raise "Unexpected URL in test: #{url}"
          end
        end
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

    context 'with chip player full data' do
      let(:tm_id) { '939745' }

      let(:torriani_html) do
        Rails.root.join('spec/fixtures/tm/player_939745.html').read
      end

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(torriani_html)
      end

      it 'returns player price in thousands' do
        expect(parser.call[:tm_price]).to eq(500_000)
      end
    end
  end
end
