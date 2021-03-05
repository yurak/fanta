RSpec.describe Player, type: :model do
  subject(:player) { create(:player) }

  describe 'Associations' do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to have_many(:player_positions).dependent(:destroy) }
    it { is_expected.to have_many(:positions).through(:player_positions) }
    it { is_expected.to have_many(:player_teams).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:player_teams) }
    it { is_expected.to have_many(:round_players).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:first_name) }

    it { is_expected.to define_enum_for(:status).with_values(%i[ready problematic injured disqualified]) }
  end

  describe '#avatar_path' do
    context 'without first name' do
      let(:player) { create(:player, first_name: nil, name: 'Dida') }

      it 'returns avatar path' do
        expect(player.avatar_path).to eq("#{Player::BUCKET_URL}/player_avatars/dida.png")
      end
    end

    context 'with first name' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns avatar path' do
        expect(player.avatar_path).to eq("#{Player::BUCKET_URL}/player_avatars/pippo_inzaghi.png")
      end
    end
  end

  describe '#profile_avatar_path' do
    context 'without first name' do
      let(:player) { create(:player, first_name: nil, name: 'Dida') }

      it 'returns profile avatar path' do
        expect(player.profile_avatar_path).to eq("#{Player::BUCKET_URL}/players/dida.png")
      end
    end

    context 'with first name' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns profile avatar path' do
        expect(player.profile_avatar_path).to eq("#{Player::BUCKET_URL}/players/pippo_inzaghi.png")
      end
    end
  end

  describe '#country' do
    context 'without nationality' do
      let(:player) { create(:player) }

      it 'returns nil' do
        expect(player.country).to eq(nil)
      end
    end

    context 'with gb-eng nationality' do
      let(:player) { create(:player, nationality: 'gb-eng') }

      it 'returns nationality' do
        expect(player.country).to eq('England')
      end
    end

    context 'with gb-wls nationality' do
      let(:player) { create(:player, nationality: 'gb-wls') }

      it 'returns nationality' do
        expect(player.country).to eq('Wales')
      end
    end

    context 'with gb-sct nationality' do
      let(:player) { create(:player, nationality: 'gb-sct') }

      it 'returns nationality' do
        expect(player.country).to eq('Scotland')
      end
    end

    context 'with gb-nir nationality' do
      let(:player) { create(:player, nationality: 'gb-nir') }

      it 'returns nationality' do
        expect(player.country).to eq('Northern Ireland')
      end
    end

    context 'with ua nationality' do
      let(:player) { create(:player, nationality: 'ua') }

      it 'returns nationality' do
        expect(player.country).to eq('Ukraine')
      end
    end
  end

  describe '#full_name' do
    context 'without first name' do
      let(:player) { create(:player, first_name: nil, name: 'Dida') }

      it 'returns name' do
        expect(player.full_name).to eq('Dida')
      end
    end

    context 'with first name' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns full name' do
        expect(player.full_name).to eq('Pippo Inzaghi')
      end
    end
  end

  describe '#full_name_reverse' do
    context 'without first name' do
      let(:player) { create(:player, first_name: nil, name: 'Dida') }

      it 'returns name' do
        expect(player.full_name_reverse).to eq('Dida')
      end
    end

    context 'with first name' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns full name' do
        expect(player.full_name_reverse).to eq('Inzaghi Pippo')
      end
    end
  end

  describe '#pseudo_name' do
    context 'without pseudonym' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns full name' do
        expect(player.pseudo_name).to eq('Pippo Inzaghi')
      end
    end

    context 'with pseudonym' do
      let(:player) { create(:player, first_name: 'Filippo', name: 'Inzaghi', pseudonym: 'Pippo') }

      it 'returns pseudonym' do
        expect(player.pseudo_name).to eq('Pippo')
      end
    end
  end

  describe '#path_name' do
    context 'without first name' do
      let(:player) { create(:player, first_name: nil, name: 'Dida') }

      it 'returns name' do
        expect(player.path_name).to eq('dida')
      end
    end

    context 'with first name' do
      let(:player) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

      it 'returns path name' do
        expect(player.path_name).to eq('pippo_inzaghi')
      end
    end

    context 'when name contains hyphen' do
      let(:player) { create(:player, first_name: 'Trent', name: 'Alexander-Arnold') }

      it 'returns path name' do
        expect(player.path_name).to eq('trent_alexander_arnold')
      end
    end

    context 'when name contains apostropht' do
      let(:player) { create(:player, first_name: 'Luigi', name: "Dell'Orco") }

      it 'returns path name' do
        expect(player.path_name).to eq('luigi_dellorco')
      end
    end
  end

  describe '#kit_path' do
    it 'returns kit path' do
      allow(player.club).to receive(:path_name).and_return('ac_milan')

      expect(player.kit_path).to eq('kits/kits_small/ac_milan.png')
    end
  end

  describe '#profile_kit_path' do
    it 'returns kit path' do
      allow(player.club).to receive(:path_name).and_return('ac_milan')

      expect(player.profile_kit_path).to eq('kits/ac_milan.png')
    end
  end

  #  TODO: positions_names_string...
end
