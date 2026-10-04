RSpec.describe Wishlists::PlayerUpdater do
  subject(:result) { described_class.call(user: user, player: player, wanted: wanted) }

  let(:user) { create(:user) }
  let!(:season) { Season.last || create(:season) }
  let(:tournament) { create(:tournament) }
  let(:club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: club) }
  let(:wanted) { true }

  describe 'adding' do
    it 'reports the player as wishlisted' do
      expect(result.wishlisted).to be(true)
    end

    it 'creates the list for the player own tournament' do
      expect(result.wishlist.tournament).to eq(tournament)
    end

    it 'keys the list by the current season' do
      expect(result.wishlist.season).to eq(season)
    end

    it 'stores the player' do
      expect(result.wishlist.players).to contain_exactly(player)
    end

    # A heart clicked twice against a stale page must not raise or duplicate the row.
    context 'when the player is already on the list' do
      before { described_class.call(user: user, player: player, wanted: true) }

      it { expect(result.wishlisted).to be(true) }

      it 'stores him once' do
        expect { result }.not_to change(WishlistPlayer, :count)
      end
    end
  end

  describe 'removing' do
    let(:wanted) { false }

    before { described_class.call(user: user, player: player, wanted: true) }

    it 'reports the player as gone' do
      expect(result.wishlisted).to be(false)
    end

    it 'drops the row' do
      expect(result.wishlist.reload.players).to be_empty
    end

    it 'keeps the list itself, so its sharing setting survives' do
      expect { result }.not_to change(Wishlist, :count)
    end

    context 'when he was not on the list anyway' do
      before { described_class.call(user: user, player: player, wanted: false) }

      it { expect(result.wishlisted).to be(false) }
      it { expect(result).to be_ok }
    end
  end

  describe 'a second list for the same user' do
    let(:other_player) { create(:player, club: create(:club, tournament: create(:tournament))) }

    it 'keeps one list per tournament' do
      described_class.call(user: user, player: player, wanted: true)

      expect { described_class.call(user: user, player: other_player, wanted: true) }
        .to change(Wishlist, :count).by(1)
    end
  end

  describe 'players we do not run a list for' do
    context 'with a fanta tournament' do
      let(:tournament) { create(:fanta_tournament) }

      it { expect(result).not_to be_ok }
      it { expect(result.error).to eq(:not_allowed) }
      it { expect { result }.not_to change(Wishlist, :count) }
    end

    context 'with a club outside our competitions' do
      let(:club) { create(:club, tournament: nil) }

      it { expect(result.error).to eq(:not_allowed) }
    end
  end

  describe 'the ceiling' do
    before do
      wishlist = Wishlist.fetch_or_create(user: user, tournament: tournament, season: season)
      allow(Wishlist).to receive(:fetch_or_create).and_return(wishlist)
      allow(wishlist).to receive(:full?).and_return(true)
    end

    it { expect(result.error).to eq(:full) }

    it 'stores nothing' do
      expect { result }.not_to change(WishlistPlayer, :count)
    end

    # The ceiling must never strand a player already on a full list.
    context 'when the player is already there' do
      before { create(:wishlist_player, wishlist: Wishlist.last, player: player) }

      it { expect(result).to be_ok }
      it { expect(result.wishlisted).to be(true) }
    end
  end

  # Two hearts clicked at once: the index refuses the duplicate and the player is already
  # where the user wanted him.
  describe 'when the same player is stored twice at once' do
    before do
      wishlist = Wishlist.fetch_or_create(user: user, tournament: tournament, season: season)
      allow(Wishlist).to receive(:fetch_or_create).and_return(wishlist)
      allow(wishlist.wishlist_players).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
    end

    it { expect(result.wishlisted).to be(true) }
    it { expect(result).to be_ok }
  end
end
