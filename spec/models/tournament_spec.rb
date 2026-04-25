RSpec.describe Tournament do
  subject(:tournament) { create(:tournament) }

  describe 'Associations' do
    it { is_expected.to have_many(:article_tags).dependent(:destroy) }
    it { is_expected.to have_many(:clubs).dependent(:destroy) }
    it { is_expected.to have_many(:leagues).dependent(:destroy) }
    it { is_expected.to have_many(:links).dependent(:destroy) }
    it { is_expected.to have_many(:national_teams).dependent(:destroy) }
    it { is_expected.to have_many(:player_season_stats).dependent(:destroy) }
    it { is_expected.to have_many(:tournament_rounds).dependent(:destroy) }

    it {
      expect(tournament).to have_many(:ec_clubs).class_name('Club').with_foreign_key('ec_tournament_id')
                                                .dependent(:destroy).inverse_of(:ec_tournament)
    }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :code }
    it { is_expected.to validate_uniqueness_of :code }
  end

  describe '#logo_path' do
    context 'when logo does not exist' do
      it 'returns default path' do
        expect(tournament.logo_path).to eq('tournaments/uefa.png')
      end
    end

    context 'when logo exists' do
      let(:code) { tournament.code }
      let(:file_path) { "app/assets/images/tournaments/#{code}.png" }

      it 'returns path to tournament logo' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)

        expect(tournament.logo_path).to eq("tournaments/#{code}.png")
      end
    end
  end

  describe '.with_join_stats' do
    subject(:result) { described_class.with_join_stats.find(tournament.id) }

    context 'when there are no joins' do
      it 'returns joins_count of 0' do
        expect(result.joins_count).to eq(0)
      end
    end

    context 'when join is pending with submitted bid' do
      before { create(:join, :pending, tournament: tournament, auction_bid: create(:submitted_auction_bid)) }

      it 'counts it' do
        expect(result.joins_count).to eq(1)
      end
    end

    context 'when join is pending but bid is not submitted (initial)' do
      before { create(:join, :pending, tournament: tournament) }

      it 'does not count it' do
        expect(result.joins_count).to eq(0)
      end
    end

    context 'when join is initial with submitted bid' do
      before { create(:join, tournament: tournament, auction_bid: create(:submitted_auction_bid)) }

      it 'does not count it' do
        expect(result.joins_count).to eq(0)
      end
    end

    context 'when join is rejected with submitted bid' do
      before { create(:join, :rejected, tournament: tournament, auction_bid: create(:submitted_auction_bid)) }

      it 'does not count it' do
        expect(result.joins_count).to eq(0)
      end
    end

    context 'when join is approved with submitted bid' do
      before { create(:join, :approved, tournament: tournament, auction_bid: create(:submitted_auction_bid)) }

      it 'does not count it' do
        expect(result.joins_count).to eq(0)
      end
    end
  end

  describe '#national?' do
    context 'without national teams' do
      it 'returns false' do
        expect(tournament.national?).to be(false)
      end
    end

    context 'with national teams' do
      it 'returns true' do
        create_list(:national_team, 2, tournament: tournament)

        expect(tournament.national?).to be(true)
      end
    end
  end
end
