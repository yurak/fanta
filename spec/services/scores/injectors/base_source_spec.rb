RSpec.describe Scores::Injectors::BaseSource do
  subject(:injector) { concrete_class.new(tournament_round) }

  let(:concrete_class) do
    Class.new(described_class) do
      attr_reader :injected_matches

      def initialize(tournament_round)
        super
        @injected_matches = []
      end

      def inject_match_scores(tournament_match)
        @injected_matches << tournament_match
      end
    end
  end

  let(:tournament_round) { create(:tournament_round) }

  describe '#call' do
    context 'with a regular (club) tournament' do
      let!(:match_with_url) { create(:tournament_match, tournament_round: tournament_round, page_url: '/some/match') }
      let!(:match_without_url) { create(:tournament_match, tournament_round: tournament_round, page_url: '') }

      it 'calls inject_match_scores only for matches with a page_url' do
        injector.call
        expect(injector.injected_matches).to contain_exactly(match_with_url)
      end

      it 'skips matches with an empty page_url' do
        injector.call
        expect(injector.injected_matches).not_to include(match_without_url)
      end
    end

    context 'when all matches have empty page_url' do
      before do
        create(:tournament_match, tournament_round: tournament_round, page_url: '')
        create(:tournament_match, tournament_round: tournament_round, page_url: '')
      end

      it 'does not call inject_match_scores' do
        injector.call
        expect(injector.injected_matches).to be_empty
      end
    end

    context 'when there are no matches' do
      it 'does not call inject_match_scores' do
        injector.call
        expect(injector.injected_matches).to be_empty
      end
    end

    context 'with a national tournament' do
      let(:national_team) { create(:national_team) }
      let(:tournament_round) { create(:tournament_round, tournament: national_team.tournament) }
      let!(:national_match) { create(:national_match, tournament_round: tournament_round, page_url: '/nat/match') }
      let!(:national_match_no_url) { create(:national_match, tournament_round: tournament_round, page_url: '') }

      it 'iterates over national_matches' do
        injector.call
        expect(injector.injected_matches).to contain_exactly(national_match)
      end

      it 'skips national matches with empty page_url' do
        injector.call
        expect(injector.injected_matches).not_to include(national_match_no_url)
      end
    end
  end

  describe '#matches (private)' do
    context 'with a regular tournament' do
      let!(:tm) { create(:tournament_match, tournament_round: tournament_round) }

      it 'returns tournament_matches' do
        expect(injector.send(:matches)).to include(tm)
      end
    end

    context 'with a national tournament' do
      let(:national_team) { create(:national_team) }
      let(:tournament_round) { create(:tournament_round, tournament: national_team.tournament) }
      let!(:nm) { create(:national_match, tournament_round: tournament_round) }

      it 'returns national_matches' do
        expect(injector.send(:matches)).to include(nm)
      end
    end
  end
end
