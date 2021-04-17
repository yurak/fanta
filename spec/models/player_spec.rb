RSpec.describe Player, type: :model do
  subject(:player) { create(:player) }

  let(:player_with_name) { create(:player, first_name: nil, name: 'Dida') }
  let(:player_with_full_name) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

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
      it 'returns avatar path' do
        expect(player_with_name.avatar_path).to eq("#{Player::BUCKET_URL}/player_avatars/dida.png")
      end
    end

    context 'with first name' do
      it 'returns avatar path' do
        expect(player_with_full_name.avatar_path).to eq("#{Player::BUCKET_URL}/player_avatars/pippo_inzaghi.png")
      end
    end
  end

  describe '#profile_avatar_path' do
    context 'without first name' do
      it 'returns profile avatar path' do
        expect(player_with_name.profile_avatar_path).to eq("#{Player::BUCKET_URL}/players/dida.png")
      end
    end

    context 'with first name' do
      it 'returns profile avatar path' do
        expect(player_with_full_name.profile_avatar_path).to eq("#{Player::BUCKET_URL}/players/pippo_inzaghi.png")
      end
    end
  end

  describe '#country' do
    context 'without nationality' do
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
      it 'returns name' do
        expect(player_with_name.full_name).to eq('Dida')
      end
    end

    context 'with first name' do
      it 'returns full name' do
        expect(player_with_full_name.full_name).to eq('Pippo Inzaghi')
      end
    end
  end

  describe '#full_name_reverse' do
    context 'without first name' do
      it 'returns name' do
        expect(player_with_name.full_name_reverse).to eq('Dida')
      end
    end

    context 'with first name' do
      it 'returns full name' do
        expect(player_with_full_name.full_name_reverse).to eq('Inzaghi Pippo')
      end
    end
  end

  describe '#pseudo_name' do
    context 'without pseudonym' do
      it 'returns full name' do
        expect(player_with_full_name.pseudo_name).to eq('Pippo Inzaghi')
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
      it 'returns name' do
        expect(player_with_name.path_name).to eq('dida')
      end
    end

    context 'with first name' do
      it 'returns path name' do
        expect(player_with_full_name.path_name).to eq('pippo_inzaghi')
      end
    end

    context 'when name contains hyphen' do
      let(:player) { create(:player, first_name: 'Trent', name: 'Alexander-Arnold') }

      it 'returns path name' do
        expect(player.path_name).to eq('trent_alexander_arnold')
      end
    end

    context 'when name contains apostrophe' do
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

  describe '#position_names' do
    let(:player) { create(:player, :with_pos_w_a) }

    it 'returns array with position names' do
      expect(player.position_names).to eq(%w[W A])
    end
  end

  describe '#position_sequence_number' do
    context 'when player has one position' do
      let(:player) { create(:player, :with_pos_a) }

      it 'returns position id' do
        expect(player.position_sequence_number).to eq(Position.find_by(name: 'A').id)
      end
    end

    context 'when player has multiple positions' do
      let(:player) { create(:player, :with_pos_w_a) }

      it 'returns first position id' do
        expect(player.position_sequence_number).to eq(Position.find_by(name: 'W').id)
      end
    end
  end

  describe '#chart_info' do
    context 'when player has no matches with score' do
      it 'returns arrays without data' do
        expect(player.chart_info).to eq([{ data: {}, name: 'Total score' }, { data: {}, name: 'Base score' }])
      end
    end

    context 'when player has matches with score' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns arrays with total data' do
        expect(player.chart_info.first[:data].values).to eq(['5.5', '6.0', '14.0'])
      end

      it 'returns arrays with base data' do
        expect(player.chart_info.last[:data].values).to eq(['6.0', '6.0', '8.0'])
      end
    end
  end

  describe '#season_scores_count' do
    context 'when player has no matches with score' do
      it 'returns zero' do
        expect(player.season_scores_count).to eq(0)
      end
    end

    context 'when player has matches with score' do
      let(:player) { create(:player, :with_scores) }

      it 'returns count of matches with score' do
        expect(player.season_scores_count).to eq(3)
      end
    end

    context 'when player has matches with score and bonuses' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns count of matches with score' do
        expect(player.season_scores_count).to eq(3)
      end
    end
  end

  describe '#season_average_score' do
    context 'when player has no matches with score' do
      it 'returns zero' do
        expect(player.season_average_score).to eq(0)
      end
    end

    context 'when player has matches with score' do
      let(:player) { create(:player, :with_scores) }

      it 'returns average score' do
        expect(player.season_average_score).to eq(6.67)
      end
    end

    context 'when player has matches with score and bonuses' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns average score without bonuses' do
        expect(player.season_average_score).to eq(6.67)
      end
    end
  end

  describe '#season_average_result_score' do
    context 'when player has no matches with score' do
      it 'returns zero' do
        expect(player.season_average_result_score).to eq(0)
      end
    end

    context 'when player has matches with score' do
      let(:player) { create(:player, :with_scores) }

      it 'returns average result score' do
        expect(player.season_average_result_score).to eq(6.67)
      end
    end

    context 'when player has matches with score and bonuses' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns average result score with bonuses' do
        expect(player.season_average_result_score).to eq(8.5)
      end
    end
  end

  describe '#season_matches_with_scores' do
    context 'when player has no matches in season' do
      it 'returns empty array' do
        expect(player.season_matches_with_scores).to eq([])
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores) }

      it 'returns array with round_players' do
        expect(player.season_matches_with_scores).to eq(player.round_players)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores, :with_second_season) }

      it 'returns array with not all round_players' do
        expect(player.season_matches_with_scores).not_to eq(player.round_players)
      end
    end
  end

  describe '#season_bonus_count(bonus)' do
    context 'when player has no matches in season' do
      it 'returns zero' do
        expect(player.season_bonus_count('goals')).to eq(0)
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns season bonus count' do
        expect(player.season_bonus_count('goals')).to eq(2)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores_n_bonuses, :with_second_season) }

      it 'returns last season bonus count' do
        expect(player.season_bonus_count('goals')).to eq(3)
      end
    end
  end

  describe '#season_cards_count(card)' do
    context 'when player has no matches in season' do
      it 'returns zero' do
        expect(player.season_cards_count('yellow_card')).to eq(0)
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns season cards count' do
        expect(player.season_cards_count('yellow_card')).to eq(1)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores_n_bonuses, :with_second_season) }

      it 'returns last season cards count' do
        expect(player.season_cards_count('yellow_card')).to eq(2)
      end
    end
  end
end
