# spec/services/players/transfermarkt/position_parser_spec.rb
require 'rails_helper'

RSpec.describe Players::Transfermarkt::PositionParser do
  describe '#call' do
    subject(:parser) { described_class.new(player, year) }

    let(:year)   { 2023 }
    let(:player) { create(:player, tm_id: '406040') }

    context 'when player is nil' do
      let(:player) { nil }

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end

    context 'when player has no tm_id' do
      let(:player) { create(:player, tm_id: nil) }

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end

    context 'when positions page exists' do
      let(:positions_html) do
        Rails.root.join('spec/fixtures/tm/positions_406040_2023.html').read
      end

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(positions_html)
      end

      it 'returns a hash' do
        result = parser.call
        expect(result).to be_a(Hash)
      end

      it 'returns non-empty stats' do
        result = parser.call
        expect(result.values.sum).to be > 0
      end

      it 'parses FW matches count' do
        result = parser.call
        expect(result['FW']).to eq(21)
      end

      it 'parses ST matches count' do
        result = parser.call
        expect(result['ST']).to eq(16)
      end

      it 'parses W matches count' do
        result = parser.call
        expect(result['W']).to eq(6)
      end

      it 'parses AM matches count' do
        result = parser.call
        expect(result['AM']).to eq(1)
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

    describe 'cache_key' do
      let(:received_args) { {} }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do |_i, _url, **kwargs|
          received_args.merge!(kwargs)
          '<html></html>'
        end
        parser.call
      end

      it 'uses tm_id and year in cache key' do
        expect(received_args[:cache_key]).to eq("positions_#{player.tm_id}_#{year}")
      end
    end

    describe 'TM_HEADLESS env' do
      let(:positions_html) { Rails.root.join('spec/fixtures/tm/positions_406040_2023.html').read }
      let(:received_args) { {} }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do |_i, _url, **kwargs|
          received_args.merge!(kwargs)
          positions_html
        end
      end

      context 'when TM_HEADLESS is false' do
        before do
          allow(ENV).to receive(:fetch).with('TM_HEADLESS', 'true').and_return('false')
          parser.call
        end

        it 'passes headless: false to BrowserClient' do
          expect(received_args[:headless]).to be(false)
        end
      end

      context 'when TM_HEADLESS is true (default)' do
        before do
          allow(ENV).to receive(:fetch).with('TM_HEADLESS', 'true').and_return('true')
          parser.call
        end

        it 'passes headless: true to BrowserClient' do
          expect(received_args[:headless]).to be(true)
        end
      end
    end
  end
end
