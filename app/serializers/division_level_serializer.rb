class DivisionLevelSerializer < ActiveModel::Serializer
  attributes :id
  attributes :level
  attributes :leagues

  def leagues
    League.includes(:division).joins(:division)
          .preload(ordered_results: :team)
          .by_season(instance_options[:season_id])
          .by_tournament(instance_options[:tournament_id])
          .where(divisions: { level: object.level })
          .order('divisions.number')
          .map { |l| LeagueBaseSerializer.new(l, results: true) }
  end
end
