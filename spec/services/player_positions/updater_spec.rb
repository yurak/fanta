RSpec.describe PlayerPositions::Updater do
  describe '#call' do
    context 'when player is missing' do
      it 'returns false' do
        expect(described_class.new(nil, ['CB']).call).to be(false)
      end
    end

    context 'when tm positions are blank' do
      let(:player) { create(:player) }

      before do
        create(:player_position, player: player, position: position_by_human_name('CB'))
      end

      it 'returns nil' do
        expect(described_class.new(player, []).call).to be_nil
      end

      it 'does not change player positions count' do
        expect { described_class.new(player, []).call }.not_to change(player.player_positions, :count)
      end
    end

    context 'when tm positions differ from existing positions' do
      let(:player) { create(:player) }
      let(:tm_positions) { %w[DM CB] }

      before do
        create(:player_position, player: player, position: position_by_human_name('CB'))
        create(:player_position, player: player, position: position_by_human_name('FW'))
      end

      it 'returns compact and sorted tm positions' do
        expect(described_class.new(player, tm_positions).call).to eq(%w[CB DM])
      end

      it 'keeps and adds expected player positions' do
        described_class.new(player, tm_positions).call

        expect(player.positions.reload.map(&:human_name)).to contain_exactly('CB', 'DM')
      end

      it 'creates new player position for missing tm position' do
        described_class.new(player, tm_positions).call

        player_position = player.player_positions.joins(:position).find_by(positions: { human_name: 'DM' })
        expect(player_position).to be_present
      end

      it 'keeps the same total positions count' do
        expect { described_class.new(player, tm_positions).call }.not_to change(player.player_positions, :count)
      end
    end

    context 'when tm positions match existing positions' do
      let(:player) { create(:player) }
      let(:tm_positions) { %w[FW CB] }

      before do
        create(:player_position, player: player, position: position_by_human_name('CB'))
        create(:player_position, player: player, position: position_by_human_name('FW'))
      end

      it 'does not change player positions count' do
        expect { described_class.new(player, tm_positions).call }.not_to change(player.player_positions, :count)
      end

      it 'returns compact and sorted tm positions' do
        expect(described_class.new(player, tm_positions).call).to eq(%w[CB FW])
      end
    end

    context 'when tm positions include nil and require changes' do
      let(:player) { create(:player) }

      before do
        create(:player_position, player: player, position: position_by_human_name('CB'))
      end

      it 'raises an error' do
        expect { described_class.new(player, ['CB', nil]).call }.to raise_error(NoMethodError)
      end
    end

    context 'when tm_new_positions is not provided' do
      let(:player) { create(:player) }
      let(:current_year) { Season.last.start_year }

      before do
        create(:player_position, player: player, position: position_by_human_name('CB'))
        allow(Players::Transfermarkt::PositionMapper).to receive(:call).and_return(['CB'])
      end

      it 'calls transfermarkt mapper with player and season year' do
        described_class.new(player).call

        expect(Players::Transfermarkt::PositionMapper).to have_received(:call).with(player, current_year)
      end

      it 'returns mapper positions' do
        expect(described_class.new(player).call).to eq(['CB'])
      end
    end

    def position_by_human_name(human_name)
      Position.find_by(human_name: human_name)
    end
  end
end
