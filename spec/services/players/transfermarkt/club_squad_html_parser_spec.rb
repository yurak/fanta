require 'rails_helper'

RSpec.describe Players::Transfermarkt::ClubSquadHtmlParser do
  let(:tm_club_id) { '27' }
  let(:fixture) { Rails.root.join('spec/fixtures/tm/club_squad_27.html').read }

  def stub_html(body)
    response = instance_double(RestClient::Response, body: body)
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  before { stub_html(fixture) }

  describe '#call' do
    subject(:ids) { described_class.call(tm_club_id) }

    context 'when tm_club_id is blank' do
      it { expect(described_class.call(nil)).to eq([]) }
    end

    it 'returns the whole squad' do
      expect(ids.size).to eq(29)
    end

    it 'returns ids as strings' do
      expect(ids).to all(match(/\A\d+\z/))
    end

    it 'returns unique ids' do
      expect(ids.uniq).to eq(ids)
    end

    it 'requests the detailed squad page of the current season' do
      ids
      expect(RestClient::Request).to have_received(:execute)
        .with(hash_including(url: 'https://www.transfermarkt.com/club/kader/verein/27/plus/1'))
    end

    context 'when the page has no squad table' do
      before { stub_html('<html><body>no squad here</body></html>') }

      it { is_expected.to eq([]) }
    end

    context 'when a player is linked more than once in a row' do
      before do
        stub_html(<<~HTML)
          <table class="items"><tbody>
            <tr>
              <td class="hauptlink"><a href="/x/profil/spieler/111">X</a></td>
              <td class="hauptlink"><a href="/x/profil/spieler/111">X</a></td>
            </tr>
            <tr><td class="hauptlink"><a href="/y/profil/spieler/222">Y</a></td></tr>
          </tbody></table>
        HTML
      end

      it 'de-duplicates the ids' do
        expect(ids).to eq(%w[111 222])
      end
    end
  end
end
