RSpec.describe NationalSquads::WikiFetcher do
  subject(:pages) { described_class.call(teams) }

  let(:teams) { ['Germany'] }

  def api_response(body)
    instance_double(RestClient::Response, body: body.to_json)
  end

  before { allow(RestClient::Request).to receive(:execute).and_return(api_response(payload)) }

  context 'with an article that answers directly' do
    let(:payload) do
      { 'query' => { 'pages' => [{ 'title' => 'Germany national football team',
                                   'revisions' => [{ 'timestamp' => '2026-09-23T12:00:00Z',
                                                     'slots' => { 'main' => { 'content' => 'squad text' } } }] }] } }
    end

    it 'keys the answer by our team name' do
      expect(pages.keys).to eq(['Germany'])
    end

    it 'hands back the wikitext' do
      expect(pages['Germany'][:wikitext]).to eq('squad text')
    end

    it 'hands back when it was last edited' do
      expect(pages['Germany'][:edited_at]).to eq('2026-09-23T12:00:00Z')
    end
  end

  # Wikipedia answers under the title it redirected TO, so the reply has to be indexed under the
  # title we asked for as well, or the team reads as missing.
  context 'with an article that redirects' do
    let(:teams) { ['Sweden'] }
    let(:payload) do
      { 'query' => {
        'redirects' => [{ 'from' => "Sweden men's national football team", 'to' => 'Sweden national football team' }],
        'pages' => [{ 'title' => 'Sweden national football team',
                      'revisions' => [{ 'timestamp' => '2026-09-23T12:00:00Z',
                                        'slots' => { 'main' => { 'content' => 'swedish squad' } } }] }]
      } }
    end

    it 'follows it back to our team name' do
      expect(pages['Sweden'][:wikitext]).to eq('swedish squad')
    end
  end

  context 'with a team the API knows nothing about' do
    let(:payload) { { 'query' => { 'pages' => [{ 'title' => 'Germany national football team', 'missing' => true }] } } }

    it 'leaves it out rather than inventing an empty squad' do
      expect(pages).to be_empty
    end
  end

  describe '.article_for' do
    let(:payload) { { 'query' => { 'pages' => [] } } }

    it 'builds the usual title' do
      expect(described_class.article_for('Germany')).to eq('Germany national football team')
    end

    it 'uses the override where the two names differ' do
      expect(described_class.article_for('Czechia')).to eq('Czech Republic national football team')
    end
  end
end
