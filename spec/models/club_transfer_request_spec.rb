require 'rails_helper'

RSpec.describe ClubTransferRequest do
  it 'defaults to the pending status' do
    expect(build(:club_transfer_request).status).to eq('pending')
  end

  it 'is valid with valid attributes' do
    expect(build(:club_transfer_request)).to be_valid
  end

  it 'is invalid without a new_club_name' do
    expect(build(:club_transfer_request, new_club_name: nil)).not_to be_valid
  end

  it 'is invalid without a start_date' do
    expect(build(:club_transfer_request, start_date: nil)).not_to be_valid
  end

  describe '#teams_status' do
    let(:tournament) { create(:tournament) }
    let(:old_club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: old_club) }

    it 'is :green when the player stays in the championship' do
      new_club = create(:club, tournament: tournament)
      request = build(:club_transfer_request, player: player, new_club: new_club, new_club_name: new_club.name)

      expect(request.teams_status).to eq(:green)
    end

    it 'is :yellow when the player leaves the championship and has no teams' do
      new_club = create(:club, tournament: create(:tournament))
      request = build(:club_transfer_request, player: player, new_club: new_club, new_club_name: new_club.name)

      expect(request.teams_status).to eq(:yellow)
    end

    it 'is :red when the player leaves the championship and is owned by teams' do
      new_club = create(:club, tournament: create(:tournament))
      create(:player_team, player: player)
      request = build(:club_transfer_request, player: player, new_club: new_club, new_club_name: new_club.name)

      expect(request.teams_status).to eq(:red)
    end
  end
end
