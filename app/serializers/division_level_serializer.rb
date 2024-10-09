class DivisionLevelSerializer < ActiveModel::Serializer
  attributes :id
  attributes :level
  attributes :leagues

  def leagues
    League.includes(:division).joins(:division)
          .by_season(instance_options[:season_id])
          .by_tournament(instance_options[:tournament_id])
          .where(divisions: { level: object.level })
          .map { |l| LeagueBaseSerializer.new(l, results: true) }
  end
end
