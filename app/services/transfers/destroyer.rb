module Transfers
  class Destroyer < ApplicationService
    attr_reader :transfer_id

    def initialize(transfer_id:)
      @transfer_id = transfer_id
    end

    def call
      return false unless transfer

      ActiveRecord::Base.transaction do
        transfer.team.update(budget: transfer.team.budget + transfer.price)
        PlayerTeam.find_by(team: transfer.team, player: transfer.player).destroy
        transfer.destroy
      end
    end

    private

    def transfer
      @transfer ||= Transfer.find_by(id: transfer_id)
    end
  end
end
