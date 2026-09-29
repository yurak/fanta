class WishlistPlayer < ApplicationRecord
  belongs_to :wishlist
  belongs_to :player
end
