RSpec.describe PlayerFormHelper do
  describe '#players_last_rounds_form(players, current_round)' do
    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }
    let(:player) { create(:player) }
    let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 3) }
    let(:two_rounds_ago) { create(:tournament_round, tournament: tournament, season: season, number: 1) }
    let(:previous_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }

    context 'without a current round' do
      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([player], nil)).to eq({})
      end
    end

    context 'without players' do
      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([], current_round)).to eq({})
      end
    end

    context 'when there are no prior rounds' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 1) }

      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([player], current_round)).to eq({})
      end
    end

    context 'when fewer than five prior rounds exist' do
      let(:cells) { helper.players_last_rounds_form([player], current_round)[player.id] }

      before do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: true, played_minutes: 90, score: 7.0)
        create(:round_player, player: player, tournament_round: previous_round, in_squad: true, played_minutes: 30, score: 6.0)
      end

      it 'pads missing rounds on the left, oldest to newest' do
        expect(cells.pluck(:state)).to eq(%w[empty empty empty full part])
      end

      it 'fills the score of the played rounds' do
        expect(cells.last(2).pluck(:score)).to eq(%w[7 6])
      end
    end

    context 'when the round is scored' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }
      let(:cells) { helper.players_last_rounds_form([player], current_round)[player.id] }

      it 'shows the base rating of a closed round, not the score with bonuses' do
        create(:round_player, player: player, tournament_round: two_rounds_ago,
                              in_squad: true, played_minutes: 90, score: 6.5, final_score: 9.5)

        expect(cells.last[:score]).to eq('6.5')
      end

      it 'shows the base rating while the round is not closed yet' do
        create(:round_player, player: player, tournament_round: two_rounds_ago,
                              in_squad: true, played_minutes: 90, score: 6.5, final_score: 0)

        expect(cells.last[:score]).to eq('6.5')
      end

      it 'shows no number when the round has no rating yet' do
        create(:round_player, player: player, tournament_round: two_rounds_ago,
                              in_squad: true, played_minutes: 90, score: 0, final_score: 0)

        expect(cells.last).to eq({ state: 'full', score: nil })
      end
    end

    context 'when the club had no match in the round' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }
      let(:player) { create(:player, club: create(:club)) }
      let(:cells) { helper.players_last_rounds_form([player], current_round)[player.id] }

      before { two_rounds_ago }

      it 'is skipped when the other clubs played that round' do
        create(:tournament_match, tournament_round: two_rounds_ago)

        expect(cells.last[:state]).to eq('skipped')
      end

      it 'is out when the round has no tournament matches at all' do
        expect(cells.last[:state]).to eq('out')
      end

      it 'keeps the regular state when the club played that round' do
        create(:tournament_match, tournament_round: two_rounds_ago, host_club: player.club)
        create(:round_player, player: player, tournament_round: two_rounds_ago,
                              in_squad: true, played_minutes: 90, score: 7.0)

        expect(cells.last).to eq({ state: 'full', score: '7' })
      end
    end

    context 'when mapping the previous round state' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }

      before { two_rounds_ago } # the prior round must exist even when the player has no round_player in it

      def last_state
        helper.players_last_rounds_form([player], current_round)[player.id].last[:state]
      end

      it 'is bench when in squad without minutes' do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: true, played_minutes: 0)
        expect(last_state).to eq('bench')
      end

      it 'is out when not in squad' do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: false)
        expect(last_state).to eq('out')
      end

      it 'is out when no round_player exists' do
        expect(last_state).to eq('out')
      end
    end
  end

  describe '#form_rounds(current_round, count)' do
    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }
    let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 7) }

    before do
      (1..6).each { |number| create(:tournament_round, tournament: tournament, season: season, number: number) }
      create(:tournament_round, tournament: tournament, season: create(:season), number: 4) # other season
      create(:tournament_round, tournament: create(:tournament), season: season, number: 4) # other tournament
    end

    it 'returns up to count prior rounds of the same tournament and season, oldest to newest' do
      expect(helper.form_rounds(current_round, 5).map(&:number)).to eq([2, 3, 4, 5, 6])
    end
  end

  describe '#player_form_cell(round_player)' do
    it 'is out when the round_player is nil' do
      expect(helper.player_form_cell(nil)).to eq({ state: 'out' })
    end

    it 'is out when the player was not in the squad' do
      expect(helper.player_form_cell(build(:round_player, in_squad: false))[:state]).to eq('out')
    end

    it 'is bench when in the squad without minutes' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 0))[:state]).to eq('bench')
    end

    it 'is part when played fewer than 60 minutes' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 45, score: 6.0))[:state]).to eq('part')
    end

    it 'is full when played 60 minutes or more' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 90, score: 7.0))[:state]).to eq('full')
    end
  end

  describe '#player_form_score(round_player)' do
    it 'uses the base rating and ignores bonuses' do
      expect(helper.player_form_score(build(:round_player, final_score: 8.0, score: 6.0))).to eq('6')
    end

    it 'rounds the base rating to one decimal' do
      expect(helper.player_form_score(build(:round_player, final_score: 0, score: 6.53))).to eq('6.5')
    end

    it 'is nil when the round is not scored yet' do
      expect(helper.player_form_score(build(:round_player, final_score: 0, score: 0))).to be_nil
    end
  end

  describe '#player_form_row(player, rounds, cells, pad)' do
    let(:player) { create(:player) }
    let(:round) { create(:tournament_round) }
    let(:round_player) { create(:round_player, player: player, tournament_round: round, in_squad: true, played_minutes: 90, score: 7.0) }

    it 'prepends the padding to the mapped cells' do
      cells = { [player.id, round.id] => round_player }
      row = helper.player_form_row(player, [round], cells, [{ state: 'empty' }])
      expect(row.pluck(:state)).to eq(%w[empty full])
    end
  end
end
