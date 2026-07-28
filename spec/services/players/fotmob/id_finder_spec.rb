require 'rails_helper'

RSpec.describe Players::Fotmob::IdFinder do
  def payload
    {
      'squadMemberSuggest' => [
        {
          'options' => [
            { 'text' => 'Erling Haaland|737066',
              'payload' => { 'id' => '737066', 'teamId' => 8456, 'teamName' => 'Manchester City' } },
            { 'text' => 'Some Other|111', 'payload' => { 'id' => '111', 'teamName' => 'Other FC' } }
          ]
        }
      ]
    }
  end

  before do
    response = instance_double(RestClient::Response, body: JSON.generate(payload))
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  describe '#call' do
    subject(:candidates) { described_class.call('Haaland') }

    it 'returns a candidate per option' do
      expect(candidates.size).to eq(2)
    end

    it 'parses id, name and club' do
      expect(candidates.first).to eq(id: '737066', name: 'Erling Haaland', team_name: 'Manchester City')
    end

    context 'when the name is blank' do
      it { expect(described_class.call('')).to eq([]) }
    end

    context 'when Fotmob returns no suggestions' do
      before do
        response = instance_double(RestClient::Response, body: JSON.generate({}))
        allow(RestClient::Request).to receive(:execute).and_return(response)
      end

      it { expect(candidates).to eq([]) }
    end

    context 'when the request fails' do
      before { allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception) }

      it { expect(candidates).to eq([]) }
    end
  end
end
