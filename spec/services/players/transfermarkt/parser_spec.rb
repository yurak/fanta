RSpec.describe Players::Transfermarkt::Parser do
  describe '#call' do
    subject(:parser) { described_class.new(tm_id) }

    before do
      create(:season, start_year: 2023, end_year: 2024)
    end

    let(:tm_id) { '569598' }

    context 'without tm_id' do
      let(:tm_id) { nil }

      it { expect(parser.call).to be(false) }
    end

    context 'with player full data' do
      let!(:club) { create(:club, name: 'Milan', tm_name: 'AC Milan') }

      it 'returns player first name' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:first_name]).to eq('Youssouf')
        end
      end

      it 'returns player last name' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:name]).to eq('Fofana')
        end
      end

      it 'returns player country code' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:nationality]).to eq('fr')
        end
      end

      it 'returns player club id' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:club_id]).to eq(club.id)
        end
      end

      it 'returns player club name' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:club_name]).to eq(club.name)
        end
      end

      it 'returns player main position' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:position1]).to eq('M')
        end
      end

      it 'returns player second position' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:position2]).to eq('C')
        end
      end

      it 'returns player third position' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:position3]).to be_nil
        end
      end

      it 'returns player price in millions' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:tm_price]).to eq(30_000_000)
        end
      end

      it 'returns player height' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:height]).to eq('185')
        end
      end

      it 'returns player number' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:number]).to eq('19')
        end
      end

      it 'returns player birth date' do
        VCR.use_cassette 'player_tm_parser_fofana' do
          expect(parser.call[:birth_date]).to eq('10.01.1999')
        end
      end
    end

    context 'with chip player full data' do
      let(:tm_id) { '939745' }

      it 'returns player price in thousands' do
        VCR.use_cassette 'player_tm_parser_torriani' do
          expect(parser.call[:tm_price]).to eq(500_000)
        end
      end
    end
  end
end
