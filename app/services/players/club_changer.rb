module Players
  class ClubChanger < ApplicationService
    def initialize(player:, new_club_id:, start_date:, contract_expires_on:, loan:)
      @player = player
      @new_club_id = new_club_id.to_i
      @start_date = start_date
      @contract_expires_on = contract_expires_on.presence
      @loan = loan
    end

    def call
      new_club = Club.find(@new_club_id)
      ActiveRecord::Base.transaction do
        create_transfer_record(new_club)
        trigger_left_tournament unless same_tournament_move?(new_club)
        @player.update!(club: new_club)
      end
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
      false
    end

    private

    def create_transfer_record(new_club)
      ClubTransfer.create!(
        player: @player,
        old_club: @player.club,
        old_club_name: @player.club&.name,
        new_club: new_club,
        new_club_name: new_club.name,
        start_date: @start_date,
        loan: @loan,
        contract_expires_on: @contract_expires_on
      )
    end

    def trigger_left_tournament
      @player.teams.each { |team| Transfers::Seller.call(@player, team, :left) }
    end

    def same_tournament_move?(new_club)
      old_club = @player.club
      return false unless old_club

      new_club.active? && old_club.tournament_id.present? && old_club.tournament_id == new_club.tournament_id
    end
  end
end
