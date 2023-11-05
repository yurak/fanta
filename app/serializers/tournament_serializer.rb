class TournamentSerializer < ActiveModel::Serializer
  attributes :id, :logo_path, :name, :leagues

  def leagues
    object.leagues.viewable.serial.map { |l| LeagueSerializer.new(l) }
  end
end
