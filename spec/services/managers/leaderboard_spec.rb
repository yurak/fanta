RSpec.describe Managers::Leaderboard do
  def manager_with(wins: 0, draws: 0, loses: 0, league: nil, title: false)
    league ||= create(:archived_league)
    user = create(:user)
    team = create(:team, user: user, league: league)
    create(:result, team: team, league: league, wins: wins, draws: draws, loses: loses, title: title)
    user
  end

  describe 'win_rate metric' do
    subject(:entries) { described_class.new(metric: 'win_rate').call }

    let!(:leader) { manager_with(wins: 8, loses: 2) }
    let!(:runner_up) { manager_with(wins: 5, loses: 5) }

    it 'ranks managers by win rate descending' do
      expect(entries.map(&:user_id)).to eq([leader.id, runner_up.id])
    end

    it 'assigns sequential ranks with computed values' do
      expect(entries.map { |entry| [entry.rank, entry.value] }).to eq([[1, 80.0], [2, 50.0]])
    end

    it 'exposes matches played' do
      expect(entries.first.matches).to eq(10)
    end
  end

  describe 'matches metric' do
    let!(:most_active) { manager_with(wins: 30, loses: 20) }
    let!(:less_active) { manager_with(wins: 5, loses: 5) }

    it 'ranks managers by matches played' do
      entries = described_class.new(metric: 'matches').call
      expect(entries.map { |entry| [entry.user_id, entry.value] }).to eq([[most_active.id, 50], [less_active.id, 10]])
    end
  end

  describe 'tournament filter' do
    let(:tournament) { create(:tournament) }
    let!(:inside) { manager_with(wins: 3, league: create(:archived_league, tournament: tournament)) }

    before { manager_with(wins: 3, league: create(:archived_league, tournament: create(:tournament))) }

    it 'ranks only managers from the given tournament' do
      ids = described_class.new(metric: 'win_rate', tournament_id: tournament.id).call.map(&:user_id)
      expect(ids).to contain_exactly(inside.id)
    end
  end

  describe 'min_matches filter' do
    let!(:experienced) { manager_with(wins: 60, loses: 50) }

    before { manager_with(wins: 5, loses: 5) }

    it 'keeps only managers with at least the given number of matches' do
      ids = described_class.new(metric: 'win_rate', min_matches: 100).call.map(&:user_id)
      expect(ids).to contain_exactly(experienced.id)
    end
  end

  describe 'newbie filter' do
    let!(:veteran) { manager_with(wins: 5, loses: 5, league: create(:archived_league)) }
    let!(:newbie) { manager_with(wins: 9, loses: 1, league: create(:active_league)) }

    it 'hides managers with no finished result by default' do
      expect(described_class.new(metric: 'win_rate').call.map(&:user_id)).to contain_exactly(veteran.id)
    end

    it 'includes them when include_newbies is true' do
      ids = described_class.new(metric: 'win_rate', include_newbies: true).call.map(&:user_id)
      expect(ids).to contain_exactly(veteran.id, newbie.id)
    end
  end

  describe 'demo leagues' do
    let(:user) { create(:user) }

    before do
      demo = create(:archived_league, demo: true)
      real = create(:archived_league)
      create(:result, team: create(:team, user: user, league: demo), league: demo, wins: 100)
      create(:result, team: create(:team, user: user, league: real), league: real, wins: 2, loses: 2)
    end

    it 'excludes demo results from the metric' do
      expect(described_class.new(metric: 'win_rate').entry_for(user.id).value).to eq(50.0)
    end
  end

  describe 'titles metric' do
    let(:champion) { manager_with(wins: 1) }
    let(:challenger) { manager_with(wins: 1) }

    before do
      create(:user_title, user: champion, championship_number: 1)
      create(:user_title, user: champion, championship_number: 2)
      challenger
    end

    it 'lists only managers with at least one title' do
      entries = described_class.new(metric: 'titles').call
      expect(entries.map { |entry| [entry.user_id, entry.value] }).to eq([[champion.id, 2]])
    end
  end

  describe 'titles tie-break' do
    let(:early) { manager_with(wins: 1) }
    let(:late) { manager_with(wins: 1) }

    before do
      early.update!(champion_number: 3)
      late.update!(champion_number: 7)
      create(:user_title, user: early, championship_number: 1)
      create(:user_title, user: late, championship_number: 2)
    end

    it 'ranks equal titles by smaller champion number first' do
      expect(described_class.new(metric: 'titles').call.map(&:user_id)).to eq([early.id, late.id])
    end
  end

  describe 'teams without a manager' do
    before do
      league = create(:archived_league)
      create(:result, team: create(:team, league: league), league: league, wins: 3)
    end

    it 'excludes orphan teams without raising during sort' do
      expect(described_class.new(metric: 'titles').call).to be_empty
    end
  end

  describe 'avg_total_score metric' do
    let(:user) { create(:user) }

    before do
      league = create(:archived_league)
      team = create(:team, user: user, league: league)
      create(:result, team: team, league: league, wins: 1)
      create(:lineup, team: team, tour: create(:closed_tour, league: league), final_score: 88.5)
    end

    it 'ranks by average finished mantra lineup score' do
      expect(described_class.new(metric: 'avg_total_score').entry_for(user.id).value).to eq(88.5)
    end
  end
end
