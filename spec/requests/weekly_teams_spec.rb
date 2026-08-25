RSpec.describe 'WeeklyTeams' do
  describe 'GET #show' do
    context 'when weekly team exists' do
      let(:weekly_team) { create(:weekly_team) }

      before { get weekly_team_path(weekly_team) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
    end

    context 'when weekly team has players' do
      let(:weekly_team) { create(:weekly_team, :with_player) }

      before { get weekly_team_path(weekly_team) }

      it { expect(response).to be_successful }
    end

    context 'when user is logged in' do
      let(:weekly_team) { create(:weekly_team) }

      before do
        sign_in create(:user)
        get weekly_team_path(weekly_team)
      end

      it { expect(response).to be_successful }
    end

    context 'when weekly team is auction-sourced (player without a round_player)' do
      let(:player) { create(:player, :with_pos_por) }
      let(:weekly_team) do
        create(:weekly_team, source: :auction, mode: :top, tournament: Tournament.first).tap do |wt|
          create(:weekly_team_player, weekly_team: wt, slot: wt.team_module.slots.first,
                                      round_player: nil, player: player, total: 30.0, max_price: 55)
        end
      end

      before { get weekly_team_path(weekly_team) }

      it { expect(response).to be_successful }
      it { expect(response.body).to include(player.full_name) }
    end

    context 'when weekly team is a round-based top team' do
      let(:round)       { create(:tournament_round) }
      let(:weekly_team) { create(:weekly_team, source: :round, mode: :top, round_ids: [round.id]) }

      before do
        tour = create(:closed_tour, tournament_round: round)
        team = create(:team, user: create(:user, name: 'Best Manager'), human_name: 'Champions FC')
        create(:lineup, tour: tour, team: team, final_score: 88.5)
        get weekly_team_path(weekly_team)
      end

      it { expect(response).to be_successful }

      it 'lists the top lineup of each selected round with manager, team and score' do
        aggregate_failures do
          expect(response.body).to include('Best Manager')
          expect(response.body).to include('Champions FC')
          expect(response.body).to include('88.5')
        end
      end
    end

    context 'when weekly team does not exist' do
      before { get weekly_team_path(0) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end
