RSpec.describe WishlistPlayer do
  describe 'Associations' do
    it { is_expected.to belong_to(:wishlist) }
    it { is_expected.to belong_to(:player) }
  end

  describe 'Uniqueness' do
    let(:wishlist) { create(:wishlist) }
    let(:player) { create(:player) }

    it 'refuses to store the same player twice' do
      create(:wishlist_player, wishlist: wishlist, player: player)

      expect { create(:wishlist_player, wishlist: wishlist, player: player) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
