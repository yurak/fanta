RSpec.describe Scores::Injectors::FotmobMatch do
  describe '#call' do
    subject(:injector) { described_class.new(match) }

    let(:match) { create(:tournament_match) }

    context 'with not finished match' do
      let(:match) { create(:tournament_match, source_match_id: '3901068') }

      it 'returns nil' do
        VCR.use_cassette 'fotmob_match_initial' do
          expect(injector.call).to be_nil
        end
      end
    end

    # TODO: add test cases
    context 'with finished match' do
      let(:match) { create(:tournament_match, source_match_id: '4010208') }

      it 'updates players and returns missed players data' do
        VCR.use_cassette 'fotmob_match_finished' do
          expect(injector.call).not_to be_nil
        end
      end
    end

    # TODO: add test cases
    context 'with national teams match' do
      # let(:match) { create(:tournament_match, source_match_id: '3610099') }
      # before do
      #   create(:national_match, tournament_round: match.tournament_round)
      # end

      it 'is a pending example'
      # it 'returns path name' do
      #   VCR.use_cassette 'fotmob_match_finished_national' do
      #     expect(injector.call).to be_nil
      #   end
      # end
    end
  end
end
