require 'rails_helper'
require 'playwright'

RSpec.describe Players::Transfermarkt::ClubPlayersScraper do
  subject(:scraper) { described_class.new(clubs: clubs, writer: writer) }

  let(:writer) { [] }
  let(:clubs) { [club] }
  let(:club) { create(:club, name: 'Juventus', tm_url: 'https://www.transfermarkt.com/juventus') }

  def playwright_timeout
    Playwright::TimeoutError.new(message: 'Timeout 30000ms exceeded.')
  end

  def club_page_html(*tm_ids)
    rows = tm_ids.map do |tm_id|
      <<~HTML
        <table class="inline-table">
          <tr><td class="hauptlink"><span></span><a href="/name/profil/spieler/#{tm_id}">Player</a></td></tr>
        </table>
      HTML
    end
    rows.join
  end

  def stub_browser(html)
    allow_any_instance_of(Players::Transfermarkt::BrowserClient)
      .to receive(:fetch_html).and_return(html)
  end

  def stub_parser(tm_id, result)
    allow(Players::Transfermarkt::Parser).to receive(:call).with(tm_id).and_return(result)
  end

  def stub_parser_position_skip(tm_id, result)
    allow(Players::Transfermarkt::Parser).to receive(:call).with(tm_id, position_skip: true).and_return(result)
  end

  def parser_result(overrides = {})
    { first_name: 'John', name: 'Doe', nationality: 'it', club_name: club.name,
      position1: 'D', position2: nil, position3: nil, tm_url: 'https://tm.com/1',
      tm_pos1: 'CB', tm_pos2: nil, tm_pos3: nil, tm_price: 5_000_000,
      number: 5, birth_date: '01/01/1995', height: 180 }.merge(overrides)
  end

  describe '#call' do
    context 'when club has no tm_url' do
      let(:club) { create(:club, tm_url: nil) }

      before { allow(Players::Transfermarkt::BrowserClient).to receive(:new) }

      it 'does not raise' do
        expect { scraper.call }.not_to raise_error
      end

      it 'does not call BrowserClient' do
        scraper.call
        expect(Players::Transfermarkt::BrowserClient).not_to have_received(:new)
      end
    end

    context 'when club has tm_url' do
      let(:received_args) { [] }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do |_instance, url, **kwargs|
          received_args << [url, kwargs]
          club_page_html
        end
      end

      it 'calls BrowserClient with correct args' do
        scraper.call
        expect(received_args).to include([club.tm_url, { headless: true, cache_key: "club_#{club.id}", ttl: 7 * 86_400 }])
      end
    end
  end

  describe 'processing known players' do
    before do
      create(:player, tm_id: 999, club: club)
      stub_browser(club_page_html(999))
    end

    it 'does not call Parser for existing players' do
      allow(Players::Transfermarkt::Parser).to receive(:call)
      scraper.call
      expect(Players::Transfermarkt::Parser).not_to have_received(:call)
    end

    it 'does not write anything to writer' do
      scraper.call
      expect(writer).to be_empty
    end
  end

  describe 'processing new players' do
    before do
      stub_browser(club_page_html(12_345))
      stub_parser(12_345.to_s, parser_result)
    end

    it 'calls Parser for unknown tm_id' do
      scraper.call
      expect(Players::Transfermarkt::Parser).to have_received(:call).with('12345')
    end

    it 'writes a row to the writer' do
      scraper.call
      expect(writer.length).to eq(1)
    end

    it 'includes player name in the row' do
      scraper.call
      expect(writer.first).to include('Doe')
    end

    it 'includes club name in the row' do
      scraper.call
      expect(writer.first).to include(club.name)
    end

    context 'when Parser returns nil' do
      before { stub_parser(12_345.to_s, nil) }

      it 'does not write anything to writer' do
        scraper.call
        expect(writer).to be_empty
      end
    end
  end

  describe 'missed players' do
    before do
      create(:player, tm_id: 777, club: club)
      stub_browser(club_page_html)
      stub_parser_position_skip(777, parser_result(club_name: club.name))
    end

    it 'calls Parser with position_skip for missed player' do
      scraper.call
      expect(Players::Transfermarkt::Parser).to have_received(:call).with(777, position_skip: true)
    end

    context 'when player stayed in same club' do
      it 'does not raise' do
        expect { scraper.call }.not_to raise_error
      end
    end

    context 'when player moved to another club' do
      before { stub_parser_position_skip(777, parser_result(club_name: 'Inter')) }

      it 'does not raise' do
        expect { scraper.call }.not_to raise_error
      end
    end

    context 'when Parser returns nil for missed player' do
      before { stub_parser_position_skip(777, nil) }

      it 'does not raise' do
        expect { scraper.call }.not_to raise_error
      end
    end
  end

  describe 'retry behavior' do
    context 'when BrowserClient raises RestClient::Exception' do
      let(:call_count) { { n: 0 } }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do
          call_count[:n] += 1
          raise RestClient::Exception if call_count[:n] < 3

          club_page_html
        end
      end

      it 'retries and eventually succeeds' do
        expect { scraper.call }.not_to raise_error
      end

      it 'calls BrowserClient 3 times before succeeding' do
        scraper.call
        expect(call_count[:n]).to eq(3)
      end
    end

    context 'when BrowserClient raises Playwright::TimeoutError' do
      let(:call_count) { { n: 0 } }

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do
          call_count[:n] += 1
          raise playwright_timeout if call_count[:n] < 3

          club_page_html
        end
      end

      it 'retries on Playwright::TimeoutError and succeeds' do
        expect { scraper.call }.not_to raise_error
      end
    end

    context 'when BrowserClient keeps raising after max attempts' do
      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient)
          .to receive(:fetch_html)
          .and_raise(playwright_timeout)
      end

      it 'does not raise and skips the club' do
        expect { scraper.call }.not_to raise_error
      end

      it 'does not write to writer' do
        scraper.call
        expect(writer).to be_empty
      end
    end

    context 'when Parser raises RestClient::Exception then succeeds' do
      let(:call_count) { { n: 0 } }

      before do
        stub_browser(club_page_html(55_555))
        allow(Players::Transfermarkt::Parser).to receive(:call).with('55555') do
          call_count[:n] += 1
          raise RestClient::Exception if call_count[:n] < 2

          parser_result
        end
      end

      it 'retries Parser and writes to writer' do
        scraper.call
        expect(writer.length).to eq(1)
      end
    end

    context 'when Parser raises Playwright::TimeoutError exhaustively' do
      before do
        stub_browser(club_page_html(55_555))
        allow(Players::Transfermarkt::Parser).to receive(:call).with('55555')
                                                               .and_raise(playwright_timeout)
      end

      it 'does not raise and skips writing' do
        expect { scraper.call }.not_to raise_error
      end

      it 'does not write to writer' do
        scraper.call
        expect(writer).to be_empty
      end
    end
  end

  describe 'multiple clubs' do
    let(:club2) { create(:club, name: 'Inter', tm_url: 'https://www.transfermarkt.com/inter') }
    let(:clubs) { [club, club2] }
    let(:call_urls) { [] }

    before do
      allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html) do |_instance, url, **_opts|
        call_urls << url
        club_page_html
      end
    end

    it 'does not raise' do
      expect { scraper.call }.not_to raise_error
    end

    it 'calls BrowserClient for each club' do
      scraper.call
      expect(call_urls).to contain_exactly(club.tm_url, club2.tm_url)
    end
  end
end
