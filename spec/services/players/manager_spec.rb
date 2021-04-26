RSpec.describe Players::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(player_hash) }

    let(:player) { create(:player, :with_pos_w_a) }
    let(:club_name) { player.club.name }
    let(:player_id) { player.id }
    let(:player_position1) { player.positions.first.name }
    let(:player_hash) do
      {
        'id' => player_id,
        'name' => player.name,
        'club_name' => club_name,
        'first_name' => 'Pippo',
        'nationality' => 'it',
        'position1' => player_position1,
        'position2' => nil,
        'position3' => nil,
        'tm_url' => 'https://www.transfermarkt.com'
      }
    end

    context 'with blank params' do
      let(:player_hash) { {} }

      it { expect(manager.call).to eq(false) }
    end

    context 'without club_name' do
      let(:club_name) { nil }

      it { expect(manager.call).to eq(false) }
    end

    context 'without player id' do
      let(:player_hash) do
        {
          'name' => 'Mbappe',
          'club_name' => club_name,
          'first_name' => 'Kilian',
          'nationality' => 'it',
          'position1' => player_position1
        }
      end

      it { expect(manager.call).to eq(true) }

      it 'creates player with correct name' do
        manager.call

        expect(Player.last.name).to eq('Mbappe')
      end

      it 'creates player with correct club' do
        manager.call

        expect(Player.last.club.name).to eq(club_name)
      end

      it 'creates player with correct position' do
        manager.call

        expect(Player.last.positions.first.name).to eq(player_position1)
      end
    end

    context 'without player id and positions' do
      let(:player_id) { nil }
      let(:player_position1) { nil }

      it { expect(manager.call).to eq(false) }
    end

    context 'with multiple positions' do
      let(:player_hash) do
        {
          'name' => 'Hakimi',
          'club_name' => club_name,
          'first_name' => 'Achraf',
          'nationality' => 'mr',
          'position1' => 'Dd',
          'position2' => 'Ds',
          'position3' => 'E'
        }
      end

      it { expect(manager.call).to eq(true) }

      it 'creates player with correct name' do
        manager.call

        expect(Player.last.name).to eq('Hakimi')
      end

      it 'creates player with multiple positions' do
        manager.call

        expect(Player.last.positions.count).to eq(3)
      end

      it 'creates player with correct positions names' do
        manager.call

        expect(Player.last.position_names).to eq(%w[Ds Dd E])
      end
    end

    context 'with player id and player in another club' do
      let(:club_name) { create(:club).name }

      it 'updates player club' do
        manager.call

        expect(player.reload.club.name).to eq(club_name)
      end
    end

    context 'with player id' do
      let(:player_hash) do
        {
          'id' => player_id,
          'name' => 'Hakimi',
          'club_name' => club_name,
          'first_name' => 'Achraf',
          'nationality' => 'mr',
          'tm_url' => 'https://new_url'
        }
      end

      it 'updates player name' do
        manager.call

        expect(player.reload.name).to eq('Hakimi')
      end

      it 'updates player first_name' do
        manager.call

        expect(player.reload.first_name).to eq('Achraf')
      end

      it 'updates player nationality' do
        manager.call

        expect(player.reload.nationality).to eq('mr')
      end

      it 'updates player tm_url' do
        manager.call

        expect(player.reload.tm_url).to eq('https://new_url')
      end
    end
  end
end
