RSpec.describe Player do
  subject(:player) { create(:player) }

  let(:player_with_name) { create(:player, first_name: nil, name: 'Dida') }
  let(:player_with_full_name) { create(:player, first_name: 'Pippo', name: 'Inzaghi') }

  describe 'Associations' do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to belong_to(:national_team).optional }
    it { is_expected.to have_many(:player_positions).dependent(:destroy) }
    it { is_expected.to have_many(:positions).through(:player_positions) }
    it { is_expected.to have_many(:player_teams).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:player_teams) }
    it { is_expected.to have_many(:player_bids).dependent(:destroy) }
    it { is_expected.to have_many(:player_requests).dependent(:destroy) }
    it { is_expected.to have_many(:player_season_stats).dependent(:destroy) }
    it { is_expected.to have_many(:round_players).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:tm_id) }
    it { is_expected.to validate_uniqueness_of(:fotmob_id) }
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
        expect(player.country).to be_nil
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
    context 'with avatar_name' do
      let(:player_with_avatar_name) { create(:player, name: 'Suarez', avatar_name: 'suarez_uy') }

      it 'returns avatar_path' do
        expect(player_with_avatar_name.path_name).to eq('suarez_uy')
      end
    end

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

      expect(player.kit_path).to eq('https://mantrafootball.s3-eu-west-1.amazonaws.com/kits/club_small/ac_milan.png')
    end
  end

  describe '#profile_kit_path' do
    it 'returns kit path' do
      allow(player.club).to receive(:path_name).and_return('ac_milan')

      expect(player.profile_kit_path).to eq('https://mantrafootball.s3-eu-west-1.amazonaws.com/kits/club/ac_milan.png')
    end
  end

  describe '#national_kit_path' do
    context 'without national_team' do
      it 'returns nil' do
        expect(player.national_kit_path).to be_nil
      end
    end

    context 'with national_team' do
      let(:player) { create(:player, :with_national_team) }

      it 'returns kit path' do
        allow(player.national_team).to receive(:code).and_return('ac_milan')

        expect(player.national_kit_path).to eq('https://mantrafootball.s3-eu-west-1.amazonaws.com/kits/national_small/ac_milan.png')
      end
    end
  end

  describe '#profile_national_kit_path' do
    context 'without national_team' do
      it 'returns nil' do
        expect(player.profile_national_kit_path).to be_nil
      end
    end

    context 'with national_team' do
      let(:player) { create(:player, :with_national_team) }

      it 'returns kit path' do
        allow(player.national_team).to receive(:code).and_return('ac_milan')

        expect(player.profile_national_kit_path).to eq('https://mantrafootball.s3-eu-west-1.amazonaws.com/kits/national/ac_milan.png')
      end
    end
  end

  describe '#tm_path' do
    context 'without tm_id' do
      it 'returns empty string' do
        expect(player.tm_path).to eq('')
      end
    end

    context 'with tm_id' do
      let(:player) { create(:player, tm_id: '123321') }

      it 'returns player TM path' do
        expect(player.tm_path).to eq('https://www.transfermarkt.com/player-path/profil/spieler/123321')
      end
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

  describe '#transfer_by(team)' do
    context 'when player has not team and transfer' do
      let(:team) { nil }

      it 'returns nil' do
        expect(player.transfer_by(team)).to be_nil
      end
    end

    context 'when player has not transfer' do
      let(:player) { create(:player, :with_team) }

      it 'returns nil' do
        expect(player.transfer_by(player.teams.last)).to be_nil
      end
    end

    context 'when player has one transfer' do
      let(:player) { create(:player, :with_team) }
      let!(:transfer) { create(:transfer, player: player, team: player.teams.last) }

      it 'returns transfer' do
        expect(player.transfer_by(player.teams.last)).to eq(transfer)
      end
    end

    context 'when player has multiple teams and transfers' do
      before do
        create_list(:player_team, 3, player: player)
        create(:transfer, player: player, team: player.teams.first)
      end

      it 'returns transfer by last team' do
        transfer = create(:transfer, player: player, team: player.teams.last)

        expect(player.transfer_by(player.teams.last)).to eq(transfer)
      end

      it 'returns transfer by first team' do
        expect(player.transfer_by(player.teams.first)).to eq(player.transfers.first)
      end
    end
  end

  describe '#current_average_price' do
    context 'when player has not team and transfer' do
      let(:team) { nil }

      it 'returns 0' do
        expect(player.current_average_price).to eq(0)
      end
    end

    context 'when player has one transfer' do
      let(:player) { create(:player, :with_team) }
      let!(:transfer) { create(:transfer, player: player, team: player.teams.last, price: 13) }

      it 'returns transfer price' do
        expect(player.current_average_price).to eq(transfer.price)
      end
    end

    context 'when player has multiple teams and transfers' do
      before do
        create_list(:player_team, 2, player: player)
        create(:transfer, player: player, team: player.teams.first, price: 12)
        create(:transfer, player: player, team: player.teams.last, price: 11)
      end

      it 'returns average price' do
        expect(player.current_average_price).to eq(11.5)
      end
    end
  end

  describe '#age' do
    context 'without birth_date' do
      it 'returns nil' do
        expect(player.age).to be_nil
      end
    end

    context 'with birth_date' do
      let(:player) { create(:player, birth_date: birth_date) }
      let(:birth_date) { "Jan 1, #{Time.zone.today.strftime('%Y').to_i - age}" }
      let(:age) { 21 }

      it 'returns player age' do
        expect(player.age).to eq(age)
      end
    end
  end

  describe '#team_by_league(league_id)' do
    let(:league_id) { nil }

    context 'without teams' do
      it 'returns empty array' do
        expect(player.team_by_league(league_id)).to be_nil
      end
    end

    context 'with one team' do
      let(:team) { create(:team) }
      let(:league_id) { team.league.id }

      before do
        create(:player_team, player: player, team: team)
      end

      it 'returns team by league' do
        expect(player.team_by_league(league_id)).to eq(team)
      end
    end

    context 'with multiple teams' do
      let(:team) { create(:team) }
      let(:league_id) { team.league.id }

      before do
        create(:player_team, player: player, team: team)
        create_list(:player_team, 3, player: player)
      end

      it 'returns team by league' do
        expect(player.team_by_league(league_id)).to eq(team)
      end
    end
  end

  describe '#stats_price' do
    context 'without player_season_stats' do
      it 'returns initial price' do
        expect(player.stats_price).to eq(1)
      end
    end

    context 'without player_season_stats in previous season' do
      before do
        create(:player_season_stat, position_price: 20, player: player, season: Season.last, tournament: player.club.tournament)
      end

      it 'returns initial price' do
        expect(player.stats_price).to eq(1)
      end
    end

    context 'with player_season_stats in other tournament' do
      before do
        create(:player_season_stat, position_price: 20, player: player, season: Season.last)
        create(:season)
      end

      it 'returns initial price' do
        expect(player.stats_price).to eq(1)
      end
    end

    context 'with player_season_stats from previous season in tournament' do
      before do
        create(:player_season_stat, position_price: 20, player: player, season: Season.last, tournament: player.club.tournament)
        create(:season)
      end

      it 'returns initial price' do
        expect(player.stats_price).to eq(20)
      end
    end
  end

  describe '#chart_info(matches)' do
    let(:matches) { [] }

    context 'when player has no matches with score' do
      it 'returns arrays without data' do
        expect(player.chart_info(matches)).to eq([{ data: {}, name: 'Total score' }, { data: {}, name: 'Base score' }])
      end
    end

    context 'when player has matches with score' do
      let(:player) { create(:player, :with_scores_n_bonuses) }
      let(:matches) { player.season_matches_with_scores }

      it 'returns arrays with total data' do
        expect(player.chart_info(matches).first[:data].values).to eq(%w[5.5 6.0 14.0])
      end

      it 'returns arrays with base data' do
        expect(player.chart_info(matches).last[:data].values).to eq(%w[6.0 6.0 8.0])
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

  describe '#season_ec_matches_with_scores' do
    context 'when player has no eurocup matches in season' do
      it 'returns empty array' do
        expect(player.season_ec_matches_with_scores).to eq([])
      end
    end

    context 'when player has eurocup matches in one season' do
      let(:player) { create(:player, :with_eurocup_scores) }

      it 'returns array with round_players' do
        expect(player.season_ec_matches_with_scores).to eq(player.round_players)
      end
    end
  end

  describe '#season_all_matches_with_scores' do
    context 'when player has no matches in season' do
      it 'returns empty array' do
        expect(player.season_all_matches_with_scores).to eq([])
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores) }

      it 'returns array with round_players' do
        expect(player.season_all_matches_with_scores).to eq(player.round_players)
      end
    end

    context 'when player has eurocup matches in one season' do
      let(:player) { create(:player, :with_eurocup_scores) }

      it 'returns array with round_players' do
        expect(player.season_all_matches_with_scores).to eq(player.round_players)
      end
    end

    context 'when player has championship and eurocup matches in one season' do
      let(:player) { create(:player, :with_champ_and_eurocup_scores) }

      it 'returns array with round_players' do
        expect(player.season_all_matches_with_scores).to eq(player.round_players)
      end
    end
  end

  describe '#national_matches_with_scores' do
    context 'when player has no matches in season' do
      it 'returns empty array' do
        expect(player.national_matches_with_scores).to eq([])
      end
    end

    context 'when player has national matches' do
      let(:player) { create(:player, :with_national_team) }

      it 'returns array with round_players at national team' do
        tr = create(:tournament_round, tournament: player.national_team.tournament)
        round_players = create_list(:round_player, 3, player: player, tournament_round: tr, score: 6)

        expect(player.national_matches_with_scores).to eq(round_players)
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

  describe '#season_bonus_count(matches, bonus)' do
    context 'when player has no matches in season' do
      it 'returns zero' do
        expect(player.season_bonus_count(player.season_matches_with_scores, 'goals')).to eq(0)
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns season bonus count' do
        expect(player.season_bonus_count(player.season_matches_with_scores, 'goals')).to eq(2)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores_n_bonuses, :with_second_season) }

      it 'returns last season bonus count' do
        expect(player.season_bonus_count(player.season_matches_with_scores, 'goals')).to eq(3)
      end
    end
  end

  describe '#season_cards_count(matches, card)' do
    context 'when player has no matches in season' do
      it 'returns zero' do
        expect(player.season_cards_count(player.season_matches_with_scores, 'yellow_card')).to eq(0)
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns season cards count' do
        expect(player.season_cards_count(player.season_matches_with_scores, 'yellow_card')).to eq(1)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores_n_bonuses, :with_second_season) }

      it 'returns last season cards count' do
        expect(player.season_cards_count(player.season_matches_with_scores, 'yellow_card')).to eq(2)
      end
    end
  end

  describe '#season_played_minutes(matches)' do
    context 'when player has no matches in season' do
      it 'returns zero' do
        expect(player.season_played_minutes).to eq(0)
      end
    end

    context 'when player has matches in one season' do
      let(:player) { create(:player, :with_scores_n_bonuses) }

      it 'returns season played_minutes sum' do
        expect(player.season_played_minutes).to eq(160)
      end
    end

    context 'when player has matches in multiple seasons' do
      let(:player) { create(:player, :with_scores_n_bonuses, :with_second_season) }

      it 'returns last season played_minutes sum' do
        expect(player.season_played_minutes).to eq(280)
      end
    end
  end
end
