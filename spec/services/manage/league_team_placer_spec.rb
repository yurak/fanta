RSpec.describe Manage::LeagueTeamPlacer do
  subject(:placer) { described_class.new(league, user.id) }

  let(:tournament) { create(:tournament) }
  let(:league) { create(:league, tournament: tournament) }
  let(:user) { create(:user) }

  describe 'a manager who already plays this tournament' do
    let(:old_league) { create(:league, tournament: tournament, status: :archived) }
    let!(:old_team) { create(:team, user: user, league: old_league, human_name: 'Green City', code: 'GCU') }

    it 'plans a move' do
      expect(placer.plan.action).to eq(:move)
    end

    it 'names the team that would move' do
      expect(placer.plan.source).to eq(old_team)
    end

    it 'moves it rather than creating another' do
      expect { placer.call }.not_to(change { Team.where(user: user).count })
    end

    it 'carries the team into this league' do
      placer.call

      expect(old_team.reload.league).to eq(league)
    end

    # the team is the row every result, lineup and standing of that league hangs on
    context 'when that league is still being played' do
      let(:old_league) { create(:league, tournament: tournament, status: :active) }

      it 'refuses' do
        expect(placer.plan.error).to eq(:source_league_active)
      end

      it 'leaves the team where it is' do
        expect { placer.call }.not_to(change { old_team.reload.league_id })
      end
    end
  end

  describe 'a manager who has never played this tournament' do
    let(:other) { create(:tournament) }
    let!(:current) do
      create_list(:team, 2, user: user, league: create(:league, tournament: other),
                            human_name: 'Chameleon', code: 'CHA')
    end

    before do
      # an identity he used once, long ago: the newest team of the biggest group must win
      create(:team, user: user, league: create(:league, tournament: other), human_name: 'Old Name', code: 'OLD')
    end

    it 'plans a copy' do
      expect(placer.plan.action).to eq(:copy)
    end

    it 'copies the identity he uses most, taking its newest team' do
      expect(placer.plan.source).to eq(current.max_by(&:id))
    end

    it 'creates a team in this league' do
      expect { placer.call }.to change { Team.where(user: user, league: league).count }.from(0).to(1)
    end

    it 'keeps his name, code and badge' do
      team = placer.call.team

      expect([team.human_name, team.code, team.logo_url]).to eq([current.last.human_name, current.last.code,
                                                                 current.last.logo_url])
    end

    it 'mints a slug of its own rather than reusing the source one' do
      team = placer.call.team

      expect(team.name).not_to eq(current.last.name)
    end

    it 'files it under this tournament' do
      expect(placer.call.team.tournament_id).to eq(tournament.id)
    end
  end

  describe 'what it refuses' do
    it 'reports an id nobody carries' do
      expect(described_class.new(league, 0).plan.error).to eq(:user_not_found)
    end

    it 'reports an id that is not a number' do
      expect(described_class.new(league, 'тринадцять').plan.error).to eq(:user_not_found)
    end

    it 'reports a manager who is already in the league' do
      create(:team, user: user, league: league)

      expect(placer.plan.error).to eq(:already_in_league)
    end

    it 'reports a manager with no team at all' do
      expect(placer.plan.error).to eq(:nothing_to_copy)
    end

    it 'writes nothing when it refuses' do
      expect { placer.call }.not_to change(Team, :count)
    end
  end
end
