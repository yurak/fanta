RSpec.describe RoundPlayers::Creator do
  describe '#call' do
    subject(:creator) { described_class.new(tournament_round_id) }

    let(:tournament_round) { create(:tournament_round) }
    let(:tournament_round_id) { tournament_round.id }
    let(:club) { create(:club, tournament: tournament_round.tournament) }

    context 'with invalid tournament_round id' do
      let(:tournament_round_id) { 'invalid' }

      it { expect(creator.call).to eq(false) }
    end

    context 'with existed tournament_round and players' do
      before do
        create_list(:player, 5, club: club)
        creator.call
      end

      it { expect(RoundPlayer.all.count).to eq(5) }
    end

    context 'with existed tournament_round, players and round_player' do
      before do
        players = create_list(:player, 5, club: club)
        create(:round_player, player: players.last, tournament_round: tournament_round)
        creator.call
      end

      it { expect(RoundPlayer.all.count).to eq(5) }
    end

    context 'with existed tournament_round and without players' do
      before do
        creator.call
      end

      it { expect(RoundPlayer.all.count).to eq(0) }
    end
  end
end
