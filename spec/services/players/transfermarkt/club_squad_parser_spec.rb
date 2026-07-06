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
  end
end
