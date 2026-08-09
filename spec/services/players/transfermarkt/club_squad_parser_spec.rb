require 'rails_helper'

RSpec.describe Players::Transfermarkt::ClubSquadParser do
  let(:tm_club_id) { '23826' }

  def payload
    { 'data' => { 'clubId' => '23826', 'playerIds' => %w[486046 57071 160971] } }
  end

  before do
    response = instance_double(RestClient::Response, body: JSON.generate(payload))
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  describe '#call' do
    it 'returns the squad player ids as strings' do
      expect(described_class.call(tm_club_id)).to eq(%w[486046 57071 160971])
    end

    context 'when tm_club_id is blank' do
      it { expect(described_class.call(nil)).to eq([]) }
    end

    context 'when the response has no players' do
      def payload
        { 'data' => { 'clubId' => '23826' } }
      end

      it { expect(described_class.call(tm_club_id)).to eq([]) }
    end

    context 'when the API host is unreachable' do
      before do
        allow(RestClient::Request).to receive(:execute).and_raise(SocketError, 'getaddrinfo: Name or service not known')
        allow(Players::Transfermarkt::ClubSquadHtmlParser).to receive(:call).and_return(%w[111 222])
      end

      it 'falls back to the HTML parser' do
        expect(described_class.call(tm_club_id)).to eq(%w[111 222])
      end

      it 'passes the club tm_id through' do
        described_class.call(tm_club_id)
        expect(Players::Transfermarkt::ClubSquadHtmlParser).to have_received(:call).with(tm_club_id)
      end

      it 'does not retry the dead host' do
        described_class.call(tm_club_id)
        expect(RestClient::Request).to have_received(:execute).once
      end
    end
  end
end
