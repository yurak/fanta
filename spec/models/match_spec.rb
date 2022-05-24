RSpec.describe Match, type: :model do
  subject(:match) { create(:match) }

  let(:match_with_lineups) { create(:match, :with_lineups) }
  let(:match_with_lineups_host_win) { create(:match, :with_lineups_host_win) }
  let(:match_with_lineups_draw) { create(:match, :with_lineups_draw) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tour) }
    it { is_expected.to belong_to(:host).class_name('Team') }
    it { is_expected.to belong_to(:guest).class_name('Team') }
    it { is_expected.to delegate_method(:tournament_round).to(:tour) }
  end

  describe '#host_lineup' do
    context 'when host lineup does not exist' do
      it 'returns nil' do
        expect(match.host_lineup).to be(nil)
      end
    end

    context 'when host lineup exist' do
      it 'returns host lineup' do
        host_lineup = create(:lineup, tour: match.tour, team: match.host)

        expect(match.host_lineup).to eq(host_lineup)
      end
    end
  end

  describe '#guest_lineup' do
    context 'when guest lineup does not exist' do
      it 'returns nil' do
        expect(match.guest_lineup).to be(nil)
      end
    end

    context 'when guest lineup exist' do
      it 'returns guest lineup' do
        guest_lineup = create(:lineup, tour: match.tour, team: match.guest)

        expect(match.guest_lineup).to eq(guest_lineup)
      end
    end
  end

  describe '#host_score' do
    context 'when host lineup does not exist' do
      it 'returns nil' do
        expect(match.host_score).to be(nil)
      end
    end

    context 'when host lineup exist' do
      it 'returns host lineup total score' do
        host_lineup = create(:lineup, :with_team_and_score_seven, tour: match.tour, team: match.host)

        expect(match.host_score).to eq(host_lineup.total_score)
      end
    end
  end

  describe '#guest_score' do
    context 'when guest lineup does not exist' do
      it 'returns nil' do
        expect(match.guest_score).to be(nil)
      end
    end

    context 'when guest lineup exist' do
      it 'returns guest lineup total score' do
        guest_lineup = create(:lineup, :with_team_and_score_six, tour: match.tour, team: match.guest)

        expect(match.guest_score).to eq(guest_lineup.total_score)
      end
    end
  end

  describe '#host_goals' do
    context 'when host lineup does not exist' do
      it 'returns zero' do
        expect(match.host_goals).to eq(0)
      end
    end

    context 'when host lineup exist' do
      it 'returns host lineup goals' do
        expect(match_with_lineups.host_goals).to eq(2)
      end
    end
  end

  describe '#guest_goals' do
    context 'when guest lineup does not exist' do
      it 'returns zero' do
        expect(match.guest_goals).to eq(0)
      end
    end

    context 'when guest lineup exist' do
      it 'returns guest lineup goals' do
        expect(match_with_lineups.guest_goals).to eq(4)
      end
    end
  end

  describe '#scored_goals' do
    context 'when lineup does not exist' do
      it 'returns zero' do
        expect(match.scored_goals(match.host)).to eq(0)
      end
    end

    context 'when lineup exist and team is host' do
      it 'returns match host goals' do
        expect(match_with_lineups.scored_goals(match_with_lineups.host)).to eq(2)
      end
    end

    context 'when lineup exist and team is guest' do
      it 'returns match guest goals' do
        expect(match_with_lineups.scored_goals(match_with_lineups.guest)).to eq(4)
      end
    end
  end

  describe '#missed_goals' do
    context 'when lineup does not exist' do
      it 'returns zero' do
        expect(match.missed_goals(match.host)).to eq(0)
      end
    end

    context 'when lineup exist and team is host' do
      it 'returns match guest goals' do
        expect(match_with_lineups.missed_goals(match_with_lineups.host)).to eq(4)
      end
    end

    context 'when lineup exist and team is guest' do
      it 'returns match host goals' do
        expect(match_with_lineups.missed_goals(match_with_lineups.guest)).to eq(2)
      end
    end
  end

  describe '#host_win?' do
    context 'when lineups do not exist' do
      it 'returns false' do
        expect(match.host_win?).to be(false)
      end
    end

    context 'when lineups exist and host win' do
      it 'returns true' do
        expect(match_with_lineups_host_win.host_win?).to be(true)
      end
    end

    context 'when lineups exist and host lose' do
      it 'returns false' do
        expect(match_with_lineups.host_win?).to be(false)
      end
    end

    context 'when lineups exist and draw' do
      it 'returns false' do
        expect(match_with_lineups_draw.host_win?).to be(false)
      end
    end
  end

  describe '#guest_win?' do
    context 'when lineups do not exist' do
      it 'returns false' do
        expect(match.guest_win?).to be(false)
      end
    end

    context 'when lineups exist and host win' do
      it 'returns false' do
        expect(match_with_lineups_host_win.guest_win?).to be(false)
      end
    end

    context 'when lineups exist and host lose' do
      it 'returns true' do
        expect(match_with_lineups.guest_win?).to be(true)
      end
    end

    context 'when lineups exist and draw' do
      it 'returns false' do
        expect(match_with_lineups_draw.guest_win?).to be(false)
      end
    end
  end

  describe '#draw?' do
    context 'when lineups do not exist' do
      it 'returns true' do
        expect(match.draw?).to be(true)
      end
    end

    context 'when lineups exist and host win' do
      it 'returns false' do
        expect(match_with_lineups_host_win.draw?).to be(false)
      end
    end

    context 'when lineups exist and host lose' do
      it 'returns false' do
        expect(match_with_lineups.draw?).to be(false)
      end
    end

    context 'when lineups exist and draw' do
      it 'returns true' do
        expect(match_with_lineups_draw.draw?).to be(true)
      end
    end
  end
end
