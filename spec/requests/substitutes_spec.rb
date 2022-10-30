RSpec.describe 'Substitutes' do
  let(:substitute) { create(:substitute) }

  describe 'GET #new' do
    let(:lineup) { create(:lineup, :with_match_players) }
    let(:match_player) { lineup.match_players.first }

    before do
      get new_match_player_substitute_path(match_player)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_user
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get new_match_player_substitute_path(match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_moderator
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get new_match_player_substitute_path(match_player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end

    context 'when admin is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:postponed_tour)) }

      login_admin
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get new_match_player_substitute_path(match_player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end

    context 'when admin is logged in with not available tour status' do
      let(:lineup) { create(:lineup, :with_match_players) }

      login_admin
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get new_match_player_substitute_path(match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in and match_player did not play yet' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        get new_match_player_substitute_path(match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'POST #create' do
    let(:lineup) { create(:lineup, :with_match_players) }
    let(:match_player) { lineup.match_players.first }
    let(:params) do
      {
        reserve_mp_id: lineup.match_players.last.id
      }
    end

    before do
      post match_player_substitutes_path(match_player, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_user
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        post match_player_substitutes_path(match_player, params)
      end

      it { expect(response).to redirect_to(new_match_player_substitute_path(match_player)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_moderator
      before do
        creator = instance_double(Substitutes::Creator)
        allow(Substitutes::Creator).to receive(:new).and_return(creator)
        allow(creator).to receive(:call).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        post match_player_substitutes_path(match_player, params)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_admin
      before do
        creator = instance_double(Substitutes::Creator)
        allow(Substitutes::Creator).to receive(:new).and_return(creator)
        allow(creator).to receive(:call).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        post match_player_substitutes_path(match_player, params)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in but substituter service returns false' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_admin
      before do
        creator = instance_double(Substitutes::Creator)
        allow(Substitutes::Creator).to receive(:new).and_return(creator)
        allow(creator).to receive(:call).and_return(false)
        create(:match, tour: lineup.tour, host: lineup.team)
        post match_player_substitutes_path(match_player, params)
      end

      it { expect(response).to redirect_to(new_match_player_substitute_path(match_player)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'DELETE #destroy' do
    let(:lineup) { substitute.main_mp.lineup }

    context 'when user is logged out' do
      before do
        delete match_player_substitute_path(substitute.main_mp, substitute)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }

      it 'does not destroy substitute' do
        expect(substitute.reload).to eq(substitute)
      end
    end

    context 'when user is logged in' do
      login_user
      before do
        create(:match, host: lineup.team, tour: lineup.tour)
        delete match_player_substitute_path(substitute.main_mp, substitute)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not destroy substitute' do
        expect(substitute.reload).to eq(substitute)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        create(:match, host: lineup.team, tour: lineup.tour)
        delete match_player_substitute_path(substitute.main_mp, substitute)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }

      it 'destroys substitute' do
        expect(Substitute.find_by(id: substitute.id)).to be_nil
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        create(:match, host: lineup.team, tour: lineup.tour)
        delete match_player_substitute_path(substitute.main_mp, substitute)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }

      it 'destroys substitute' do
        expect(Substitute.find_by(id: substitute.id)).to be_nil
      end
    end

    context 'when admin is logged in but substitute is not exist' do
      login_admin
      before do
        create(:match, host: lineup.team, tour: lineup.tour)
        delete match_player_substitute_path(substitute.main_mp, 'invalid_id')
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end
  end
end
