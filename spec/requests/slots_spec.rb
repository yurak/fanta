RSpec.describe 'Slots' do
  describe 'GET #index' do
    let(:params) { { format: 'json' } }

    before do
      get slots_path(params)
    end

    context 'when user is logged out' do
      it { expect(response).not_to be_successful }
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get slots_path(params)
      end

      context 'without params' do
        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to be_nil
        end

        it 'returns empty hash in eurocup_players param' do
          body = JSON(response.body)

          expect(body['eurocup_players']).to eq({})
        end
      end

      context 'with position and without tour_id' do
        let(:position_name) { Position::STRIKER }
        let(:params) { { position: position_name, format: 'json' } }

        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to eq(position_name)
        end

        it 'returns empty hash in eurocup_players param' do
          body = JSON(response.body)

          expect(body['eurocup_players']).to eq({})
        end
      end

      context 'with tour_id and without position and players' do
        let(:tour) { create(:tour) }
        let(:params) { { tour_id: tour.id, format: 'json' } }

        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to be_nil
        end

        it 'returns empty hash in eurocup_players param' do
          body = JSON(response.body)

          expect(body['eurocup_players']).to eq({})
        end
      end

      context 'with position and tour without players' do
        let(:position_name) { Position::STRIKER }
        let(:tour) { create(:tour) }
        let(:params) { { position: position_name, tour_id: tour.id, format: 'json' } }

        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to eq(position_name)
        end

        it 'returns empty hash in eurocup_players param' do
          body = JSON(response.body)

          expect(body['eurocup_players']).to eq({})
        end
      end
    end

    context 'with logged user' do
      context 'with position and tour with players' do
        let(:position_name) { Position::STRIKER }
        let(:club_name_one) { 'Milanello' }
        let(:club_name_two) { 'Lombardia' }

        login_user

        before do
          tournament = create(:tournament, eurocup: true)
          tournament_round = create(:tournament_round, tournament: tournament)
          host_club = create(:club, tournament: tournament, name: club_name_one)
          guest_club = create(:club, tournament: tournament, name: club_name_two)
          tour = create(:tour, tournament_round: tournament_round)

          create(:tournament_match, tournament_round: tournament_round, host_club: host_club, guest_club: guest_club)
          create_list(:player, 3, :with_pos_pc, club: host_club)
          create_list(:player, 3, :with_pos_pc, club: guest_club)
          get slots_path({ position: position_name, tour_id: tour.id, format: 'json' })
        end

        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to eq(position_name)
        end

        it 'returns clubs names in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'].keys).to eq([club_name_two, club_name_one])
        end

        it 'returns club_one players in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'][club_name_one].count).to eq(3)
        end

        it 'returns club_two players in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'][club_name_two].count).to eq(3)
        end
      end

      context 'with tour and players, without position' do
        let(:club_name_one) { 'Milanello' }
        let(:club_name_two) { 'Lombardia' }

        login_user

        before do
          tournament = create(:tournament, eurocup: true)
          tournament_round = create(:tournament_round, tournament: tournament)
          host_club = create(:club, tournament: tournament, name: club_name_one)
          guest_club = create(:club, tournament: tournament, name: club_name_two)
          tour = create(:tour, tournament_round: tournament_round)

          create(:tournament_match, tournament_round: tournament_round, host_club: host_club, guest_club: guest_club)
          create_list(:player, 2, :with_pos_por, club: host_club)
          create_list(:player, 4, :with_pos_pc, club: guest_club)
          get slots_path({ tour_id: tour.id, format: 'json' })
        end

        it { expect(response).to be_successful }
        it { expect(response).to have_http_status(:ok) }

        it 'returns empty position param' do
          body = JSON(response.body)

          expect(body['position']).to be_nil
        end

        it 'returns clubs names in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'].keys).to eq([club_name_two, club_name_one])
        end

        it 'returns club_one players in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'][club_name_one].count).to eq(2)
        end

        it 'returns club_two players in eurocup_players' do
          body = JSON(response.body)

          expect(body['eurocup_players'][club_name_two].count).to eq(4)
        end
      end
    end
  end
end
