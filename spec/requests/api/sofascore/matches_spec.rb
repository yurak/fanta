RSpec.describe 'Api::Sofascore::Matches' do
  let(:token) { 'test-ingest-token' }
  let(:headers) { { 'X-Ingest-Token' => token } }

  before do
    allow(Rails.application.credentials).to receive(:sofascore_ingest_token).and_return(token)
  end

  describe 'GET /api/sofascore/matches' do
    let(:tournament_round) { create(:tournament_round) }

    before do
      create(:tournament_match, tournament_round: tournament_round, source_match_id: '14090683')
      create(:tournament_match, tournament_round: tournament_round, source_match_id: '14090684')
      create(:tournament_match, tournament_round: tournament_round, source_match_id: '')
      create(:tournament_match, source_match_id: '99999999') # different round
    end

    it 'returns the sofa ids of the round matches that have one' do
      get '/api/sofascore/matches', params: { tournament_round_id: tournament_round.id }, headers: headers

      expect(response.parsed_body['data']).to contain_exactly('14090683', '14090684')
    end

    it 'rejects a missing token' do
      get '/api/sofascore/matches', params: { tournament_round_id: tournament_round.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/sofascore/matches' do
    let!(:match) { create(:tournament_match, source_match_id: '14090683') }
    let(:params) { { sofascore_id: '14090683', base_data: '{"event":{}}', lineups_data: '{"home":{}}' } }

    it 'stores the fetched json on the match' do
      post '/api/sofascore/matches', params: params, headers: headers

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(match.reload).to have_attributes(base_data: '{"event":{}}', lineups_data: '{"home":{}}')
      end
    end

    it 'injects the scores' do
      allow(Scores::Injectors::SofascoreMatch).to receive(:call)

      post '/api/sofascore/matches', params: params, headers: headers

      expect(Scores::Injectors::SofascoreMatch).to have_received(:call).with(match)
    end

    it 'returns 404 for an unknown sofa id' do
      post '/api/sofascore/matches', params: params.merge(sofascore_id: '00000000'), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'rejects an invalid token' do
      post '/api/sofascore/matches', params: params, headers: { 'X-Ingest-Token' => 'wrong' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
