RSpec.describe AuctionBids::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(auction_bid, params) }

    let(:auction_bid) { create(:auction_bid, :with_player_bids, team: team) }
    let(:team) { create(:team, :with_20_players) }
    let(:params) { {} }

    context 'without auction bid' do
      let(:auction_bid) { nil }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with initial bid status' do
      context 'with ongoing new status' do
        let(:params) { { status: 'ongoing' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'with submitted new status' do
        let(:params) { { status: 'submitted' } }

        context 'when player_bids_attributes less than vacancies' do
          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('initial')
          end
        end

        context 'when duplicate players' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '543', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('initial')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when the total price exceeds the team budget' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '129', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '543', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('initial')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when GK bids less than expected' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '543', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('initial')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when auction bid with dumped player' do
          let(:players_gk) { create_list(:player, 2, :with_pos_por) }
          let(:transfer) do
            create(:transfer, status: 'outgoing', auction: auction_bid.auction_round.auction, league: team.league, team: team)
          end
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: transfer.player.id, price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: players_gk[0].id, price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: players_gk[1].id, price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '543', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('initial')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'with valid params' do
          let(:players_gk) { create_list(:player, 3, :with_pos_por) }
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: players_gk[0].id, price: '28', id: auction_bid.player_bids[0].id },
                '1': { player_id: players_gk[1].id, price: '29', id: auction_bid.player_bids[1].id },
                '2': { player_id: players_gk[2].id, price: '27', id: auction_bid.player_bids[2].id },
                '3': { player_id: create(:player).id, price: '12', id: auction_bid.player_bids[3].id },
                '4': { player_id: create(:player).id, price: '4', id: auction_bid.player_bids[4].id },
                '5': { player_id: create(:player).id, price: '3', id: auction_bid.player_bids[5].id }
              }
            }
          end

          it 'updates status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'updates player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(28)
          end
        end
      end

      context 'with completed new status' do
        let(:params) { { status: 'completed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'with processed new status' do
        let(:params) { { status: 'processed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end
    end

    context 'with ongoing bid status' do
      let(:auction_bid) { create(:auction_bid, :with_player_bids, status: 'ongoing', team: team) }

      context 'with initial new status' do
        let(:params) { { status: 'initial' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('ongoing')
        end
      end

      context 'with submitted new status' do
        let(:params) { { status: 'submitted' } }

        context 'when player_bids_attributes less than vacancies' do
          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('ongoing')
          end
        end

        context 'when duplicate players' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '877', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('ongoing')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when the total price exceeds the team budget' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '129', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('ongoing')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when GK bids less than expected' do
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: '123', price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('ongoing')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when auction bid with dumped player' do
          let(:players_gk) { create_list(:player, 2, :with_pos_por) }
          let(:transfer) do
            create(:transfer, status: 'outgoing', auction: auction_bid.auction_round.auction, league: team.league, team: team)
          end
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: transfer.player.id, price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: players_gk[0].id, price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: players_gk[1].id, price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('ongoing')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'with valid params' do
          let(:players_gk) { create_list(:player, 3, :with_pos_por) }
          let(:params) do
            {
              status: 'submitted',
              player_bids_attributes: {
                '0': { player_id: players_gk[0].id, price: '28', id: auction_bid.player_bids[0].id },
                '1': { player_id: players_gk[1].id, price: '29', id: auction_bid.player_bids[1].id },
                '2': { player_id: players_gk[2].id, price: '27', id: auction_bid.player_bids[2].id },
                '3': { player_id: create(:player).id, price: '12', id: auction_bid.player_bids[3].id },
                '4': { player_id: create(:player).id, price: '4', id: auction_bid.player_bids[4].id },
                '5': { player_id: create(:player).id, price: '3', id: auction_bid.player_bids[5].id }
              }
            }
          end

          it 'updates status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'updates player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(28)
          end
        end
      end

      context 'with completed new status' do
        let(:params) { { status: 'completed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('ongoing')
        end
      end

      context 'with processed new status' do
        let(:params) { { status: 'processed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('ongoing')
        end
      end
    end

    context 'with submitted bid status' do
      let(:auction_bid) { create(:auction_bid, :with_player_bids, status: 'submitted', team: team) }

      context 'with initial new status' do
        let(:params) { { status: 'initial' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('submitted')
        end
      end

      context 'with ongoing new status' do
        let(:params) { { status: 'ongoing' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('submitted')
        end
      end

      context 'with completed new status' do
        let(:params) { { status: 'completed' } }

        before do
          auction_bid.auction.update(number: 2)
        end

        context 'when player_bids_attributes less than vacancies' do
          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end
        end

        context 'when duplicate players' do
          let(:params) do
            {
              status: 'completed',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when the total price exceeds the team budget' do
          let(:params) do
            {
              status: 'completed',
              player_bids_attributes: {
                '0': { player_id: '123', price: '128', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '129', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when GK bids less than expected' do
          let(:params) do
            {
              status: 'completed',
              player_bids_attributes: {
                '0': { player_id: '123', price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: '143', price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'when auction bid with dumped player' do
          let(:players_gk) { create_list(:player, 2, :with_pos_por) }
          let(:transfer) do
            create(:transfer, status: 'outgoing', auction: auction_bid.auction_round.auction, league: team.league, team: team)
          end
          let(:params) do
            {
              status: 'completed',
              player_bids_attributes: {
                '0': { player_id: transfer.player.id, price: '28', id: auction_bid.player_bids[0] },
                '1': { player_id: players_gk[0].id, price: '29', id: auction_bid.player_bids[1] },
                '2': { player_id: players_gk[1].id, price: '27', id: auction_bid.player_bids[2] },
                '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
                '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
                '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
              }
            }
          end

          it 'does not change status' do
            manager.call

            expect(auction_bid.reload.status).to eq('submitted')
          end

          it 'does not update player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(1)
          end
        end

        context 'with valid params' do
          let(:players_gk) { create_list(:player, 3, :with_pos_por) }
          let(:params) do
            {
              status: 'completed',
              player_bids_attributes: {
                '0': { player_id: players_gk[0].id, price: '28', id: auction_bid.player_bids[0].id },
                '1': { player_id: players_gk[1].id, price: '29', id: auction_bid.player_bids[1].id },
                '2': { player_id: players_gk[2].id, price: '27', id: auction_bid.player_bids[2].id },
                '3': { player_id: create(:player).id, price: '12', id: auction_bid.player_bids[3].id },
                '4': { player_id: create(:player).id, price: '4', id: auction_bid.player_bids[4].id },
                '5': { player_id: create(:player).id, price: '3', id: auction_bid.player_bids[5].id }
              }
            }
          end

          it 'updates status' do
            manager.call

            expect(auction_bid.reload.status).to eq('completed')
          end

          it 'updates player_bid price' do
            manager.call

            expect(auction_bid.player_bids[0].reload.price).to eq(28)
          end
        end
      end

      context 'with processed new status' do
        let(:params) { { status: 'processed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('submitted')
        end
      end
    end

    context 'with completed bid status' do
      let(:auction_bid) { create(:auction_bid, :with_player_bids, status: 'completed', team: team) }

      context 'with initial new status' do
        let(:params) { { status: 'initial' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('completed')
        end
      end

      context 'with ongoing new status and with duplicate players' do
        let(:params) do
          {
            status: 'ongoing',
            player_bids_attributes: {
              '0': { player_id: '111', price: '128', id: auction_bid.player_bids[0] },
              '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
              '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
              '3': { player_id: '333', price: '12', id: auction_bid.player_bids[3] },
              '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] },
              '5': { player_id: '787', price: '3', id: auction_bid.player_bids[5] }
            }
          }
        end

        it 'updates status' do
          manager.call

          expect(auction_bid.reload.status).to eq('ongoing')
        end

        it 'does not update player_bid price' do
          manager.call

          expect(auction_bid.player_bids[0].reload.price).to eq(1)
        end
      end

      context 'with submitted new status' do
        let(:params) { { status: 'submitted' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('completed')
        end
      end

      context 'with processed new status' do
        let(:params) { { status: 'processed' } }

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('completed')
        end
      end
    end

    context 'with processed bid status' do
      let(:auction_bid) { create(:auction_bid, status: 'processed') }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with a join-flow bid (no auction_round)' do
      let(:auction_bid) { create(:auction_bid, :with_eleven_empty_player_bids, auction_round: nil, team: team) }
      let(:players_gk) { create_list(:player, 1, :with_pos_por) }
      let(:other_players) { create_list(:player, 10) }

      let(:valid_params) do
        all_players = players_gk + other_players
        {
          status: 'submitted',
          player_bids_attributes: all_players.each_with_index.to_h do |player, i|
            [i.to_s.to_sym, { player_id: player.id, price: '10', id: auction_bid.player_bids[i].id }]
          end
        }
      end

      context 'with valid params' do
        let(:params) { valid_params }

        it 'updates status to submitted' do
          manager.call

          expect(auction_bid.reload.status).to eq('submitted')
        end

        it 'updates player_bid price' do
          manager.call

          expect(auction_bid.player_bids[0].reload.price).to eq(10)
        end
      end

      context 'when fewer than JOIN_SLOTS players provided' do
        let(:params) do
          {
            status: 'submitted',
            player_bids_attributes: {
              '0': { player_id: players_gk[0].id, price: '10', id: auction_bid.player_bids[0].id }
            }
          }
        end

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'when total price exceeds INITIAL_BUDGET' do
        let(:params) do
          all_players = players_gk + other_players
          {
            status: 'submitted',
            player_bids_attributes: all_players.each_with_index.to_h do |player, i|
              [i.to_s.to_sym, { player_id: player.id, price: '25', id: auction_bid.player_bids[i].id }]
            end
          }
        end

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'when GK count is below MIN_GK_INIT' do
        let(:params) do
          players = other_players + create_list(:player, 1)
          {
            status: 'submitted',
            player_bids_attributes: players.each_with_index.to_h do |player, i|
              [i.to_s.to_sym, { player_id: player.id, price: '10', id: auction_bid.player_bids[i].id }]
            end
          }
        end

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'when duplicate players' do
        let(:params) do
          {
            status: 'submitted',
            player_bids_attributes: {
              '0': { player_id: players_gk[0].id, price: '10', id: auction_bid.player_bids[0].id },
              '1': { player_id: players_gk[0].id, price: '10', id: auction_bid.player_bids[1].id }
            }
          }
        end

        it 'does not change status' do
          manager.call

          expect(auction_bid.reload.status).to eq('initial')
        end
      end

      context 'when a player would be dumped in a regular auction' do
        let(:dumped_player) { create(:player, :with_pos_por) }
        let(:params) do
          all_players = [dumped_player] + other_players
          {
            status: 'submitted',
            player_bids_attributes: all_players.each_with_index.to_h do |player, i|
              [i.to_s.to_sym, { player_id: player.id, price: '10', id: auction_bid.player_bids[i].id }]
            end
          }
        end

        it 'updates status (dumped check skipped without auction_round)' do
          manager.call

          expect(auction_bid.reload.status).to eq('submitted')
        end
      end
    end
  end
end
