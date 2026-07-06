module Players
  class ClubChanger < ApplicationService
    def initialize(player:, new_club_id:)
      @player = player
      @new_club_id = new_club_id.to_i
    end

    def call
      new_club = Club.find(@new_club_id)
      return false if new_club.id == @player.club_id

      ActiveRecord::Base.transaction do
        same_tournament_move?(new_club) ? notify_club_change(new_club) : trigger_left_tournament
        @player.update!(club: new_club)
      end
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
      false
    end

    private

    def trigger_left_tournament
      @player.teams.each { |team| Transfers::Seller.call(@player, team, :left) }
    end

    def notify_club_change(new_club)
      @player.teams.each { |team| TelegramBot::PlayerClubChangedNotifier.call(@player, team, new_club) }
    end

    def same_tournament_move?(new_club)
      old_club = @player.club
      return false unless old_club

      new_club.active? && old_club.tournament_id.present? && old_club.tournament_id == new_club.tournament_id
    end
  end
end
