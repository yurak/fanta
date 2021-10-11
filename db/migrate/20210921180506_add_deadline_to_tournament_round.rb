class AddDeadlineToTournamentRound < ActiveRecord::Migration[5.2]
  def change
    add_column :tournament_rounds, :deadline, :datetime

    TournamentRound.all.each do |tr|
      next unless tr.tours.any?

      tr.update(deadline: tr.tours.last.deadline)
    end
  end
end
