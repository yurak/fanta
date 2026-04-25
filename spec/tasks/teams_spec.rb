# rubocop:disable RSpec/DescribeClass, RSpec/MultipleDescribes
require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/teams')
Rake::Task.define_task(:environment)

RSpec.describe 'teams rake tasks' do
  def reenable(task_name)
    Rake::Task[task_name].reenable
  end

  describe 'teams:cleanup_orphans' do
    before { reenable('teams:cleanup_orphans') }

    it 'delegates to Teams::Tasks.cleanup_orphans with dry_run: true by default' do
      allow(Teams::Tasks).to receive(:cleanup_orphans)
      Rake::Task['teams:cleanup_orphans'].invoke
      expect(Teams::Tasks).to have_received(:cleanup_orphans).with(dry_run: true)
    end

    it 'delegates with dry_run: false when argument is "false"' do
      allow(Teams::Tasks).to receive(:cleanup_orphans)
      Rake::Task['teams:cleanup_orphans'].invoke('false')
      expect(Teams::Tasks).to have_received(:cleanup_orphans).with(dry_run: false)
    end
  end

  describe 'teams:reset' do
    before { reenable('teams:reset') }

    it 'resets budget on team_one' do
      team = create(:team, budget: 100)
      Rake::Task['teams:reset'].invoke
      expect(team.reload.budget).to eq(Team::DEFAULT_BUDGET)
    end

    it 'resets budget on team_two' do
      team = create(:team, budget: 150)
      Rake::Task['teams:reset'].invoke
      expect(team.reload.budget).to eq(Team::DEFAULT_BUDGET)
    end
  end

  describe 'teams:reset_league' do
    before { reenable('teams:reset_league') }

    context 'when league does not exist' do
      let!(:team) { create(:team, budget: 100) }

      it 'does not reset any teams' do
        Rake::Task['teams:reset_league'].invoke('0')
        expect(team.reload.budget).to eq(100)
      end
    end

    context 'when league exists' do
      let(:league) { create(:league) }
      let!(:team) { create(:team, league: league, budget: 100) }
      let!(:other_team) { create(:team, budget: 100) }

      it 'resets teams in that league' do
        Rake::Task['teams:reset_league'].invoke(league.id.to_s)
        expect(team.reload.budget).to eq(Team::DEFAULT_BUDGET)
      end

      it 'does not reset teams in other leagues' do
        Rake::Task['teams:reset_league'].invoke(league.id.to_s)
        expect(other_team.reload.budget).to eq(100)
      end
    end
  end

  describe 'teams:reset_tournament' do
    before { reenable('teams:reset_tournament') }

    context 'when neither tournament nor season exists' do
      let!(:team) { create(:team, budget: 100) }

      it 'does not reset any teams' do
        Rake::Task['teams:reset_tournament'].invoke('0', '0')
        expect(team.reload.budget).to eq(100)
      end
    end

    context 'when tournament and season exist' do
      let(:season) { create(:season) }
      let(:league) { create(:active_league, season: season) }
      let!(:team) { create(:team, league: league, budget: 100) }

      it 'resets teams in that tournament and season' do
        Rake::Task['teams:reset_tournament'].invoke(league.tournament.id.to_s, season.id.to_s)
        expect(team.reload.budget).to eq(Team::DEFAULT_BUDGET)
      end
    end
  end
end

RSpec.describe Teams::Tasks do
  let(:orphan_team) { create(:team, league: nil) }

  describe '.orphan_teams' do
    subject(:result) { described_class.orphan_teams }

    context 'with a team that has no dependencies' do
      before { orphan_team }

      it 'includes it' do
        expect(result).to include(orphan_team)
      end
    end

    context 'with a team that has a league' do
      let!(:team) { create(:team) }

      it 'excludes it' do
        expect(result).not_to include(team)
      end
    end

    context 'with a team that has a join' do
      before { create(:join, team: orphan_team, tournament: create(:tournament)) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has an auction bid' do
      before { create(:auction_bid, team: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has player_teams' do
      before { create(:player_team, team: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has results' do
      before { create(:result, team: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has transfers' do
      before { create(:transfer, team: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has lineups' do
      before { create(:lineup, team: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has host matches' do
      before { create(:match, host: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end

    context 'with a team that has guest matches' do
      before { create(:match, guest: orphan_team) }

      it 'excludes it' do
        expect(result).not_to include(orphan_team)
      end
    end
  end

  describe '.cleanup_orphans' do
    before { orphan_team }

    context 'when dry_run: true' do
      it 'does not delete orphan teams' do
        expect { described_class.cleanup_orphans(dry_run: true) }.not_to change(Team, :count)
      end
    end

    context 'when dry_run: false' do
      it 'deletes orphan teams' do
        expect { described_class.cleanup_orphans(dry_run: false) }.to change(Team, :count).by(-1)
      end

      it 'does not delete teams with dependencies' do
        create(:team) # has league
        expect { described_class.cleanup_orphans(dry_run: false) }.to change(Team, :count).by(-1)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleDescribes
