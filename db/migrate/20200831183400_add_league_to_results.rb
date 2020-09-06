class AddLeagueToResults < ActiveRecord::Migration[5.2]
  def change
    add_reference :results, :league, foreign_key: true

    Result.all.each do |result|
      result.update(league: result.team.league)
    end
  end
end
