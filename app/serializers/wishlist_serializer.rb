class WishlistSerializer < ActiveModel::Serializer
  attributes :id
  attributes :shared
  attributes :players_count
  attributes :max_players
  attributes :owner

  attribute :tournament do
    TournamentSerializer.new(object.tournament)
  end

  attribute :season do
    SeasonSerializer.new(object.season)
  end

  attribute :editable do
    object.owned_by?(instance_options[:current_user])
  end

  def players_count
    object.wishlist_players.size
  end

  def max_players
    Wishlist::MAX_PLAYERS
  end

  def owner
    { id: object.user_id, name: object.user.name }
  end
end
