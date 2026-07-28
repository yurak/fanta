RSpec.describe Manage::LeagueStandings do
  subject(:standings) { described_class.new(league, league.results.ordered) }

  let(:league) { create(:active_league) }
  let(:leader_team) { create(:team, league: league) }
  let!(:leader) { create(:result, league: league, team: leader_team, points: 30) }
  let!(:runner_up) { create(:result, league: league, team: create(:team, league: league), points: 20) }

  before do
    t1 = create(:closed_tour, league: league)
    t2 = create(:closed_tour, league: league)
    create(:lineup, team: leader_team, tour: t1, creation_type: :manual)
    create(:lineup, team: leader_team, tour: t2, creation_type: :auto_cloned)
    create_list(:tour, 3, league: league)
  end

  describe '#lineup_pct' do
    it 'batches counts equal to Result#lineup_pct for every result' do
      results = league.results.ordered.to_a
      expect(results.map { |result| standings.lineup_pct(result) }).to eq(results.map(&:lineup_pct))
    end

    it 'computes the manual lineup percentage for a team with lineups' do
      expect(standings.lineup_pct(leader)).to eq(50)
    end

    it 'returns 0 for a team without lineups' do
      expect(standings.lineup_pct(runner_up)).to eq(0)
    end
  end

  describe '#crownable?' do
    it 'matches Result#crownable? for every result' do
      results = league.results.ordered.to_a
      expect(results.map { |result| standings.crownable?(result) }).to eq(results.map(&:crownable?))
    end

    it 'is crownable for the leader when the points gap exceeds remaining tours' do
      expect(standings.crownable?(leader)).to be(true)
    end

    it 'is not crownable for a non-leader' do
      expect(standings.crownable?(runner_up)).to be(false)
    end
  end
end
