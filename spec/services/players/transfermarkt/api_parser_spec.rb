require 'rails_helper'

RSpec.describe Players::Transfermarkt::ApiParser do
  let(:tm_id) { '123456' }

  # rubocop:disable Metrics/MethodLength
  def api_response(overrides = {})
    {
      'name' => 'John Doe',
      'nationalityDetails' => { 'nationalities' => { 'nationalityId' => 75 } },
      'lifeDates' => { 'dateOfBirth' => '1995-01-01' },
      'attributes' => {
        'height' => 1.80,
        'contractUntil' => '2026-06-30',
        'position' => { 'shortName' => 'CB' },
        'firstSidePosition' => { 'shortName' => 'LB' },
        'secondSidePosition' => { 'shortName' => nil }
      },
      'marketValueDetails' => { 'current' => { 'value' => 5_000_000 } },
      'clubAssignments' => [
        { 'type' => 'current', 'clubId' => '506', 'shirtNumber' => 5, 'start' => '2019-07-01' }
      ]
    }.merge(overrides)
  end
  # rubocop:enable Metrics/MethodLength

  def stub_api(data)
    response = instance_double(RestClient::Response, body: JSON.generate({ 'data' => data }))
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  def stub_cache_miss
    allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
  end

  before do
    stub_cache_miss
    stub_api(api_response)
  end

  describe '#call' do
    subject(:result) { described_class.call(tm_id, position_skip: true) }

    context 'when tm_id is nil' do
      subject(:result) { described_class.call(nil, position_skip: true) }

      it { is_expected.to be(false) }
    end

    it 'returns a hash' do
      expect(result).to be_a(Hash)
    end

    describe 'name parsing' do
      it 'extracts first_name from all but last word' do
        expect(result[:first_name]).to eq('John')
      end

      it 'extracts last name as last word' do
        expect(result[:name]).to eq('Doe')
      end

      context 'when name is single word' do
        before { stub_api(api_response('name' => 'Ronaldo')) }

        it 'returns nil for first_name' do
          expect(result[:first_name]).to be_nil
        end

        it 'returns the single word as name' do
          expect(result[:name]).to eq('Ronaldo')
        end
      end
    end

    describe 'nationality' do
      it 'maps nationality ID to country code' do
        expect(result[:nationality]).to eq('it')
      end

      context 'when nationality ID is unknown' do
        before { stub_api(api_response('nationalityDetails' => { 'nationalities' => { 'nationalityId' => 9999 } })) }

        it 'returns nil' do
          expect(result[:nationality]).to be_nil
        end
      end

      context 'when nationalityDetails is missing' do
        before { stub_api(api_response('nationalityDetails' => nil)) }

        it 'returns nil' do
          expect(result[:nationality]).to be_nil
        end
      end
    end

    describe 'birth_date' do
      it 'returns date of birth in DD/MM/YYYY format' do
        expect(result[:birth_date]).to eq('01/01/1995')
      end

      context 'when date is invalid' do
        before { stub_api(api_response('lifeDates' => { 'dateOfBirth' => 'not-a-date' })) }

        it 'returns nil' do
          expect(result[:birth_date]).to be_nil
        end
      end

      context 'when dateOfBirth is missing' do
        before { stub_api(api_response('lifeDates' => {})) }

        it 'returns nil' do
          expect(result[:birth_date]).to be_nil
        end
      end
    end

    describe 'height' do
      it 'converts from meters to centimeters' do
        expect(result[:height]).to eq(180)
      end

      context 'when height is nil' do
        before { stub_api(api_response('attributes' => api_response['attributes'].merge('height' => nil))) }

        it 'returns nil' do
          expect(result[:height]).to be_nil
        end
      end
    end

    describe 'price' do
      it 'returns market value as integer' do
        expect(result[:tm_price]).to eq(5_000_000)
      end

      context 'when marketValueDetails is missing' do
        before { stub_api(api_response('marketValueDetails' => nil)) }

        it 'returns 0' do
          expect(result[:tm_price]).to eq(0)
        end
      end
    end

    describe 'number' do
      it 'returns shirt number from current assignment' do
        expect(result[:number]).to eq(5)
      end

      context 'when there is no current assignment' do
        before do
          stub_api(api_response('clubAssignments' => [
                                  { 'type' => 'loan', 'clubId' => '506', 'shirtNumber' => 9 }
                                ]))
        end

        it 'returns nil' do
          expect(result[:number]).to be_nil
        end
      end
    end

    describe 'positions' do
      it 'returns tm_pos1' do
        expect(result[:tm_pos1]).to eq('CB')
      end

      it 'returns tm_pos2' do
        expect(result[:tm_pos2]).to eq('LB')
      end

      it 'returns nil for tm_pos3 when not present' do
        expect(result[:tm_pos3]).to be_nil
      end
    end

    describe 'club_joined_on' do
      it 'returns ISO8601 string' do
        expect(result[:club_joined_on]).to eq('2019-07-01')
      end

      it 'is a String, not a Date' do
        expect(result[:club_joined_on]).to be_a(String)
      end

      context 'when start date is missing' do
        before do
          stub_api(api_response('clubAssignments' => [
                                  { 'type' => 'current', 'clubId' => '506', 'shirtNumber' => 5 }
                                ]))
        end

        it 'returns nil' do
          expect(result[:club_joined_on]).to be_nil
        end
      end

      context 'when start date is invalid' do
        before do
          stub_api(api_response('clubAssignments' => [
                                  { 'type' => 'current', 'clubId' => '506', 'shirtNumber' => 5, 'start' => 'not-a-date' }
                                ]))
        end

        it 'returns nil' do
          expect(result[:club_joined_on]).to be_nil
        end
      end
    end

    describe 'contract_until' do
      it 'returns ISO8601 string' do
        expect(result[:contract_until]).to eq('2026-06-30')
      end

      it 'is a String, not a Date' do
        expect(result[:contract_until]).to be_a(String)
      end

      context 'when contractUntil is missing' do
        before do
          stub_api(api_response('attributes' => api_response['attributes'].except('contractUntil')))
        end

        it 'returns nil' do
          expect(result[:contract_until]).to be_nil
        end
      end

      context 'when contractUntil is invalid' do
        before do
          stub_api(api_response('attributes' => api_response['attributes'].merge('contractUntil' => 'not-a-date')))
        end

        it 'returns nil' do
          expect(result[:contract_until]).to be_nil
        end
      end
    end

    describe 'loan' do
      it 'returns false when onLoan is not set' do
        expect(result[:loan]).to be(false)
      end

      context 'when player is on loan' do
        before do
          stub_api(api_response('clubAssignments' => [
                                  { 'type' => 'current', 'clubId' => '506', 'shirtNumber' => 5,
                                    'start' => '2019-07-01', 'onLoan' => true }
                                ]))
        end

        it 'returns true' do
          expect(result[:loan]).to be(true)
        end
      end

      context 'when there is no current assignment' do
        before { stub_api(api_response('clubAssignments' => [])) }

        it 'returns false' do
          expect(result[:loan]).to be(false)
        end
      end
    end

    describe 'tm_url' do
      it 'builds url from tm_id' do
        expect(result[:tm_url]).to include(tm_id)
      end
    end

    describe 'club lookup' do
      let!(:club) { create(:club, tm_url: 'https://www.transfermarkt.com/juventus/startseite/verein/506') }

      it 'sets club_id from matched club' do
        expect(result[:club_id]).to eq(club.id)
      end

      it 'sets club_name from matched club' do
        expect(result[:club_name]).to eq(club.name)
      end

      it 'sets tm_club_id from current assignment' do
        expect(result[:tm_club_id]).to eq('506')
      end

      it 'sets tm_club_name from matched club tm_name' do
        expect(result[:tm_club_name]).to eq(club.tm_name)
      end

      context 'when no club matches by tm_url' do
        before { stub_api(api_response('clubAssignments' => [{ 'type' => 'current', 'clubId' => '99999', 'shirtNumber' => 1 }])) }

        it 'returns nil club_id' do
          expect(result[:club_id]).to be_nil
        end

        it 'returns nil tm_club_name' do
          expect(result[:tm_club_name]).to be_nil
        end
      end

      context 'when club is matched via reserve_club_ids' do
        let!(:reserve_club) do
          create(:club, tm_url: 'https://www.transfermarkt.com/other/startseite/verein/1',
                        reserve_club_ids: ['77777'])
        end

        before do
          stub_api(api_response('clubAssignments' => [
                                  { 'type' => 'current', 'clubId' => '77777', 'shirtNumber' => 7, 'start' => '2020-01-01' }
                                ]))
        end

        it 'matches club via reserve_club_ids' do
          expect(result[:club_id]).to eq(reserve_club.id)
        end
      end

      context 'when there is no current assignment' do
        before { stub_api(api_response('clubAssignments' => [])) }

        it 'returns nil tm_club_id' do
          expect(result[:tm_club_id]).to be_nil
        end

        it 'returns nil club_id' do
          expect(result[:club_id]).to be_nil
        end
      end
    end

    describe 'retry on connection errors' do
      subject(:result) { described_class.call(tm_id, position_skip: true) }

      let(:success_response) do
        instance_double(RestClient::Response, body: JSON.generate({ 'data' => api_response }))
      end

      before { allow_any_instance_of(described_class).to receive(:sleep) }

      shared_examples 'retries once and succeeds' do |error_class|
        before do
          call_count = 0
          allow(RestClient::Request).to receive(:execute) do
            call_count += 1
            raise error_class if call_count == 1

            success_response
          end
        end

        it 'returns result' do
          expect(result).to be_a(Hash)
        end

        it 'calls the API twice' do
          result
          expect(RestClient::Request).to have_received(:execute).twice
        end
      end

      context 'when Errno::ECONNRESET occurs once' do
        it_behaves_like 'retries once and succeeds', Errno::ECONNRESET
      end

      context 'when OpenSSL::SSL::SSLError occurs once' do
        it_behaves_like 'retries once and succeeds', OpenSSL::SSL::SSLError
      end

      context 'when RestClient::ServerBrokeConnection occurs once' do
        it_behaves_like 'retries once and succeeds', RestClient::ServerBrokeConnection
      end

      context 'when error occurs on all 3 retries' do
        before do
          allow(RestClient::Request).to receive(:execute).and_raise(Errno::ECONNRESET)
        end

        it 'raises after exhausting retries' do
          expect { result }.to raise_error(Errno::ECONNRESET)
        end

        it 'attempts 4 times total (1 original + 3 retries)' do
          suppress(Errno::ECONNRESET) { result }
          expect(RestClient::Request).to have_received(:execute).exactly(4).times
        end
      end

      context 'when error occurs exactly 3 times then succeeds' do
        before do
          call_count = 0
          allow(RestClient::Request).to receive(:execute) do
            call_count += 1
            raise Errno::ECONNRESET if call_count <= 3

            success_response
          end
        end

        it 'succeeds on the 4th attempt' do
          expect(result).to be_a(Hash)
        end
      end

      context 'when retrying with backoff' do
        let(:sleep_args) { [] }

        before do
          allow_any_instance_of(described_class).to receive(:sleep) { |_, n| sleep_args << n }
          call_count = 0
          allow(RestClient::Request).to receive(:execute) do
            call_count += 1
            raise Errno::ECONNRESET if call_count <= 2

            success_response
          end
        end

        it 'sleeps 10s on first retry and 20s on second retry' do
          result
          expect(sleep_args).to eq([10, 20])
        end
      end
    end

    describe 'caching' do
      let(:cache_path) { Rails.root.join('tmp', 'transfermarkt_cache', "player_api_#{tm_id}.json") }

      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_call_original
        FileUtils.mkdir_p(cache_path.dirname)
        File.write(cache_path, JSON.generate(api_response))
        allow(File).to receive(:mtime).and_return(Time.zone.now)
      end

      after { FileUtils.rm_f(cache_path) }

      it 'does not call the API when cache is fresh' do
        described_class.call(tm_id, position_skip: true)
        expect(RestClient::Request).not_to have_received(:execute)
      end
    end
  end
end
