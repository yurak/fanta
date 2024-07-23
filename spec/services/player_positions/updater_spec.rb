RSpec.describe PlayerPositions::Updater do
  describe '#call' do
    subject(:updater) { described_class.new(player) }

    let(:player) { create(:player, tm_id: '576024') }

    before do
      create(:season, start_year: 1.year.ago.year, end_year: Time.zone.now.year)
    end

    context 'without player' do
      let(:player) { nil }

      it { expect(updater.call).to be_falsey }
    end

    context 'with player with correct position' do
      let(:pos_st) { Position.find_by(name: Position::STRIKER) }

      before do
        player.player_positions.create(position: Position.find_by(human_name: pos_st.human_name))

        VCR.use_cassette 'player_tm_position_st' do
          updater.call
        end
      end

      it 'does not update position' do
        expect(player.position_names).to contain_exactly(pos_st.name)
      end
    end

    context 'with player with incorrect position' do
      let(:pos_fw) { Position.find_by(name: Position::FORWARD) }
      let(:pos_st) { Position.find_by(name: Position::STRIKER) }

      before do
        player.player_positions.create(position: Position.find_by(human_name: pos_fw.human_name))

        VCR.use_cassette 'player_tm_position_st' do
          updater.call
        end
      end

      it 'updates position' do
        expect(player.positions.reload.map(&:human_name)).to contain_exactly(pos_st.human_name)
      end
    end

    context 'with player when the position is missing' do
      let(:player) { create(:player, tm_id: '357662') }
      let(:pos_dm) { Position.find_by(name: Position::DEFENCE_MF) }
      let(:pos_cm) { Position.find_by(name: Position::CENTER_MF) }

      before do
        player.player_positions.create(position: Position.find_by(human_name: pos_dm.human_name))

        VCR.use_cassette 'player_tm_position_dm_cm' do
          updater.call
        end
      end

      it 'adds new position' do
        expect(player.positions.reload.map(&:human_name)).to contain_exactly(pos_dm.human_name, pos_cm.human_name)
      end
    end

    context 'with player when there is an excess position' do
      let(:player) { create(:player, tm_id: '177476') }
      let(:pos_cb) { Position.find_by(name: Position::CENTER_BACK) }
      let(:pos_lb) { Position.find_by(name: Position::LEFT_BACK) }

      before do
        player.player_positions.create(position: Position.find_by(human_name: pos_cb.human_name))
        player.player_positions.create(position: Position.find_by(human_name: pos_lb.human_name))

        VCR.use_cassette 'player_tm_position_cb' do
          updater.call
        end
      end

      it 'removes excess position' do
        expect(player.positions.reload.map(&:human_name)).to contain_exactly(pos_cb.human_name)
      end
    end

    context 'with player when the position cannot be determined' do
      let(:player) { create(:player, tm_id: '14555') }
      let(:pos_gk) { Position.find_by(name: Position::GOALKEEPER) }

      before do
        player.player_positions.create(position: Position.find_by(human_name: pos_gk.human_name))

        VCR.use_cassette 'player_tm_position_not_determined' do
          updater.call
        end
      end

      it 'does not update position' do
        expect(player.positions.reload.map(&:human_name)).to contain_exactly(pos_gk.human_name)
      end
    end
  end
end
