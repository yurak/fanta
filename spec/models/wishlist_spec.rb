RSpec.describe Wishlist do
  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:wishlist_players).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:wishlist_players) }
  end

  describe '.fetch_or_create' do
    let(:user) { create(:user) }
    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }

    it 'creates the list the first time' do
      expect { described_class.fetch_or_create(user: user, tournament: tournament, season: season) }
        .to change(described_class, :count).by(1)
    end

    it 'returns the same list afterwards' do
      first = described_class.fetch_or_create(user: user, tournament: tournament, season: season)

      expect(described_class.fetch_or_create(user: user, tournament: tournament, season: season)).to eq(first)
    end

    it 'keeps one list per tournament' do
      described_class.fetch_or_create(user: user, tournament: tournament, season: season)

      expect { described_class.fetch_or_create(user: user, tournament: create(:tournament), season: season) }
        .to change(described_class, :count).by(1)
    end

    it 'keeps one list per season' do
      described_class.fetch_or_create(user: user, tournament: tournament, season: season)

      expect { described_class.fetch_or_create(user: user, tournament: tournament, season: create(:season)) }
        .to change(described_class, :count).by(1)
    end

    # The unique index is the guard, so a racing insert must resolve to the stored row.
    it 'returns the stored list when the insert loses a race' do
      stored = described_class.fetch_or_create(user: user, tournament: tournament, season: season)
      allow(described_class).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique)

      expect(described_class.fetch_or_create(user: user, tournament: tournament, season: season)).to eq(stored)
    end
  end

  describe '#readable_by?' do
    let(:owner) { create(:user) }
    let(:stranger) { create(:user) }

    context 'with a private list' do
      let(:wishlist) { create(:wishlist, user: owner) }

      it { expect(wishlist.readable_by?(owner)).to be(true) }
      it { expect(wishlist.readable_by?(stranger)).to be(false) }
      it { expect(wishlist.readable_by?(nil)).to be(false) }
    end

    context 'with a shared list' do
      let(:wishlist) { create(:wishlist, :shared, user: owner) }

      it { expect(wishlist.readable_by?(stranger)).to be(true) }
      it { expect(wishlist.readable_by?(nil)).to be(true) }
    end
  end

  describe '#full?' do
    let(:wishlist) { create(:wishlist) }

    it 'is false while there is room' do
      expect(wishlist).not_to be_full
    end

    it 'is true at the ceiling' do
      allow(wishlist.wishlist_players).to receive(:count).and_return(described_class::MAX_PLAYERS)

      expect(wishlist).to be_full
    end
  end
end
