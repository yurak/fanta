require 'rails_helper'

RSpec.describe Players::Transfermarkt::PlayerHtmlParser do
  subject(:result) { described_class.call(tm_id, position_skip: true) }

  let(:tm_id) { '811779' }
  let(:fixture) { Rails.root.join('spec/fixtures/tm/player_html_811779.html').read }
  # Minimal page carrying only the nodes the parser reads, for the edge cases the
  # full fixture cannot cover.
  let(:minimal_defaults) do
    {
      headline: '#9 John Doe', market_value: '€500k', positions: ['Centre-Forward'],
      info: {}, club_href: '/juventus/startseite/verein/506', citizenship: 'Italy'
    }
  end

  def stub_html(body)
    response = instance_double(RestClient::Response, body: body)
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  def minimal_html(**overrides)
    opts = minimal_defaults.merge(overrides)
    <<~HTML
      <html><body>
        <div class="data-header__headline-wrapper">#{opts[:headline]}</div>
        <span class="data-header__shirt-number">#{opts[:headline][/\A#\d+/]}</span>
        <div class="data-header__items"><span class="data-header__content">
          <img class="flaggenrahmen" title="#{opts[:citizenship]}" />
        </span></div>
        <div class="data-header__club"><a href="#{opts[:club_href]}">Club</a></div>
        <div class="data-header__market-value-wrapper">#{opts[:market_value]}</div>
        <div class="detail-position">
          #{opts[:positions].map { |p| "<div class='detail-position__position'>#{p}</div>" }.join}
        </div>
        <div class="info-table">
          #{opts[:info].map { |k, v| "<span class='info-table__content'>#{k}</span><span class='info-table__content'>#{v}</span>" }.join}
        </div>
      </body></html>
    HTML
  end

  before do
    allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
    stub_html(fixture)
  end

  describe '#call' do
    context 'when tm_id is nil' do
      subject(:result) { described_class.call(nil, position_skip: true) }

      it { is_expected.to be(false) }
    end

    it 'returns a hash' do
      expect(result).to be_a(Hash)
    end

    describe 'with a real profile page' do
      it 'strips the shirt number from the first name' do
        expect(result[:first_name]).to eq('Alejandro')
      end

      it 'takes the last word as the surname' do
        expect(result[:name]).to eq('Garnacho')
      end

      it 'takes the primary citizenship of a dual national' do
        expect(result[:nationality]).to eq('ar')
      end

      it 'returns birth_date in DD/MM/YYYY' do
        expect(result[:birth_date]).to eq('01/07/2004')
      end

      it 'converts height to centimetres' do
        expect(result[:height]).to eq(180)
      end

      it 'returns the market value in units' do
        expect(result[:tm_price]).to eq(28_000_000)
      end

      it 'returns the shirt number' do
        expect(result[:number]).to eq(17)
      end

      it 'returns tm_club_id from the header club link' do
        expect(result[:tm_club_id]).to eq('405')
      end

      it 'returns the main position' do
        expect(result[:tm_pos1]).to eq('LW')
      end

      it 'returns the first side position, skipping the wrapper node' do
        expect(result[:tm_pos2]).to eq('AM')
      end

      it 'returns the second side position' do
        expect(result[:tm_pos3]).to eq('RW')
      end

      it 'returns club_joined_on as an ISO8601 string' do
        expect(result[:club_joined_on]).to eq('2026-07-23')
      end

      it 'returns contract_until as an ISO8601 string' do
        expect(result[:contract_until]).to eq('2027-06-30')
      end

      it 'detects the loan from the "On loan from" row' do
        expect(result[:loan]).to be(true)
      end

      it 'builds tm_url from tm_id' do
        expect(result[:tm_url]).to include(tm_id)
      end
    end

    describe 'name parsing' do
      context 'when the name is a single word' do
        before { stub_html(minimal_html(headline: 'Ronaldo')) }

        it 'returns nil for first_name' do
          expect(result[:first_name]).to be_nil
        end

        it 'returns the single word as name' do
          expect(result[:name]).to eq('Ronaldo')
        end
      end

      context 'when the name has accented letters' do
        before { stub_html(minimal_html(headline: 'Fettahoğlu Ömer Kırtay')) }

        it 'transliterates the first name to ASCII' do
          expect(result[:first_name]).to eq('Fettahoglu Omer')
        end

        it 'transliterates the surname to ASCII' do
          expect(result[:name]).to eq('Kirtay')
        end
      end
    end

    describe 'nationality' do
      context 'when the country is renamed in Player::COUNTRY' do
        before { stub_html(minimal_html(citizenship: 'England')) }

        it 'maps it through Player::COUNTRY' do
          expect(result[:nationality]).to eq('gb-eng')
        end
      end

      context 'when there is no flag' do
        before { stub_html(minimal_html.sub(%r{<img class="flaggenrahmen".*?/>}, '')) }

        it 'returns nil' do
          expect(result[:nationality]).to be_nil
        end
      end
    end

    describe 'price' do
      context 'when the value is in thousands' do
        before { stub_html(minimal_html(market_value: '€500k Last update: 05/06/2026')) }

        it 'multiplies by a thousand' do
          expect(result[:tm_price]).to eq(500_000)
        end
      end

      context 'when the value is in millions' do
        before { stub_html(minimal_html(market_value: '€7.00m Last update: 05/06/2026')) }

        it 'multiplies by a million' do
          expect(result[:tm_price]).to eq(7_000_000)
        end
      end

      context 'when the player has no market value' do
        before { stub_html(minimal_html(market_value: '-')) }

        it 'returns 0' do
          expect(result[:tm_price]).to eq(0)
        end
      end
    end

    describe 'positions' do
      context 'when the player has a single position' do
        before { stub_html(minimal_html(positions: ['Goalkeeper'])) }

        it 'returns the main position' do
          expect(result[:tm_pos1]).to eq('GK')
        end

        it 'returns nil for tm_pos2' do
          expect(result[:tm_pos2]).to be_nil
        end

        it 'returns nil for tm_pos3' do
          expect(result[:tm_pos3]).to be_nil
        end
      end
    end

    describe 'dates' do
      context 'when the contract row is empty' do
        before { stub_html(minimal_html(info: { 'Contract expires:' => '-' })) }

        it 'returns nil for contract_until' do
          expect(result[:contract_until]).to be_nil
        end
      end

      context 'when the joined row is missing' do
        before { stub_html(minimal_html(info: {})) }

        it 'returns nil for club_joined_on' do
          expect(result[:club_joined_on]).to be_nil
        end
      end

      context 'when the birth date row is unparseable' do
        before { stub_html(minimal_html(info: { 'Date of birth/Age:' => 'not-a-date' })) }

        it 'returns nil for birth_date' do
          expect(result[:birth_date]).to be_nil
        end
      end

      context 'when "Contract there expires" is present for a loaned player' do
        before do
          stub_html(minimal_html(info: { 'Contract expires:' => '30/06/2027',
                                         'Contract there expires:' => '30/06/2032' }))
        end

        it 'reads the loan club contract, not the parent one' do
          expect(result[:contract_until]).to eq('2027-06-30')
        end
      end
    end

    describe 'loan' do
      context 'when the player is not on loan' do
        before { stub_html(minimal_html(info: { 'Joined:' => '01/07/2020' })) }

        it 'returns false' do
          expect(result[:loan]).to be(false)
        end
      end
    end

    describe 'height' do
      context 'when the height row is missing' do
        before { stub_html(minimal_html(info: {})) }

        it 'returns nil' do
          expect(result[:height]).to be_nil
        end
      end
    end

    describe 'club lookup' do
      let!(:club) { create(:club, tm_url: 'https://www.transfermarkt.com/juventus/startseite/verein/506') }

      before { stub_html(minimal_html) }

      it 'sets club_id from the matched club' do
        expect(result[:club_id]).to eq(club.id)
      end

      it 'sets club_name from the matched club' do
        expect(result[:club_name]).to eq(club.name)
      end

      it 'sets tm_club_name from the matched club tm_name' do
        expect(result[:tm_club_name]).to eq(club.tm_name)
      end

      context 'when no club matches' do
        before { stub_html(minimal_html(club_href: '/x/startseite/verein/99999')) }

        it 'returns nil club_id' do
          expect(result[:club_id]).to be_nil
        end
      end

      context 'when the header has no club link' do
        before { stub_html(minimal_html.sub(%r{<a href="/juventus.*?</a>}, '')) }

        it 'returns nil tm_club_id' do
          expect(result[:tm_club_id]).to be_nil
        end

        it 'returns nil club_id' do
          expect(result[:club_id]).to be_nil
        end
      end
    end

    describe 'caching' do
      let(:cache_path) { Rails.root.join('tmp', 'transfermarkt_cache', "player_html_#{tm_id}.html") }

      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_call_original
        FileUtils.mkdir_p(cache_path.dirname)
        cache_path.write(fixture)
      end

      after { FileUtils.rm_f(cache_path) }

      it 'does not hit the network when the cache is fresh' do
        result
        expect(RestClient::Request).not_to have_received(:execute)
      end
    end
  end
end
