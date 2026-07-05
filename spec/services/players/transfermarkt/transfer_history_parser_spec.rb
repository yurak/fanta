require 'rails_helper'

RSpec.describe Players::Transfermarkt::TransferHistoryParser do
  let(:tm_id) { '999000111' }

  # rubocop:disable Metrics/MethodLength
  def payload
    {
      'transfers' => [
        {
          'url' => '/eljif-elmas/transfers/spieler/400489/transfer_id/5909893',
          'from' => { 'href' => '/napoli/transfers/verein/6195/saison_id/2025', 'clubName' => 'Napoli' },
          'to' => { 'href' => '/leipzig/transfers/verein/23826/saison_id/2025', 'clubName' => 'Leipzig' },
          'dateUnformatted' => '2026-06-30', 'season' => '25/26',
          'marketValue' => '€13.00m', 'fee' => 'End of loan', 'upcoming' => false
        },
        {
          'url' => '/eljif-elmas/transfers/spieler/400489/transfer_id/5111111',
          'from' => { 'href' => '/leipzig/transfers/verein/23826/saison_id/2024', 'clubName' => 'Leipzig' },
          'to' => { 'href' => '/torino/transfers/verein/416/saison_id/2024', 'clubName' => 'Torino' },
          'dateUnformatted' => '2025-01-30', 'season' => '24/25',
          'marketValue' => '€18.00m', 'fee' => 'loan transfer', 'upcoming' => false
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength

  before do
    allow_any_instance_of(described_class).to receive(:read_cache).and_return(nil)
    allow_any_instance_of(described_class).to receive(:write_cache)
    response = instance_double(RestClient::Response, body: JSON.generate(payload))
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  describe '#call' do
    subject(:transfers) { described_class.call(tm_id) }

    it { expect(transfers.size).to eq(2) }

    it 'parses the tm_transfer_id from the url' do
      expect(transfers.first[:tm_transfer_id]).to eq(5_909_893)
    end

    it 'parses the destination club id from the href' do
      expect(transfers.first[:new_tm_club_id]).to eq('23826')
    end

    it 'parses the origin club id from the href' do
      expect(transfers.first[:old_tm_club_id]).to eq('6195')
    end

    it 'parses the date' do
      expect(transfers.first[:start_date]).to eq(Date.new(2026, 6, 30))
    end

    it 'does not flag an end-of-loan return as a loan' do
      expect(transfers.first[:loan]).to be(false)
    end

    it 'flags a loan transfer as a loan' do
      expect(transfers.last[:loan]).to be(true)
    end

    context 'when tm_id is blank' do
      it { expect(described_class.call(nil)).to eq([]) }
    end

    context 'when a transfer is missing a date' do
      let(:tm_id) { '1' }

      before do
        broken = { 'transfers' => [payload['transfers'].first.merge('dateUnformatted' => nil)] }
        response = instance_double(RestClient::Response, body: JSON.generate(broken))
        allow(RestClient::Request).to receive(:execute).and_return(response)
      end

      it { expect(transfers).to eq([]) }
    end
  end
end
