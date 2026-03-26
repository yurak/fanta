# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Results::TotalScoreUpdater do
  subject(:updater) { described_class.new(league) }

  let(:league) { create(:active_league) }
  let(:team)   { create(:team, league: league) }
  let(:result) { create(:result, team: team, league: league, total_score: 0) }

  before { result }

  context 'when team has no lineups' do
    it 'sets total_score to 0' do
      updater.call
      expect(result.reload.total_score).to eq(0)
    end
  end

  context 'when team has lineups in the league' do
    let(:tour) { create(:tour, league: league) }

    before do
      create(:lineup, team: team, tour: tour, final_score: 45.5)
      create(:lineup, team: team, tour: tour, final_score: 30.0)
    end

    it 'updates total_score with the sum of lineup scores' do
      updater.call
      expect(result.reload.total_score).to eq(75.5)
    end
  end

  context 'when team has lineups in another league' do
    let(:other_league) { create(:active_league) }
    let(:other_tour)   { create(:tour, league: other_league) }

    before { create(:lineup, team: team, tour: other_tour, final_score: 100.0) }

    it 'does not count lineups from other leagues' do
      updater.call
      expect(result.reload.total_score).to eq(0)
    end
  end

  context 'when league has multiple teams' do
    let(:team2)   { create(:team, league: league) }
    let(:result2) { create(:result, team: team2, league: league, total_score: 0) }
    let(:tour)    { create(:tour, league: league) }

    before do
      result2
      create(:lineup, team: team,  tour: tour, final_score: 55.0)
      create(:lineup, team: team2, tour: tour, final_score: 80.0)
    end

    it 'updates total_score for team' do
      updater.call
      expect(result.reload.total_score).to eq(55.0)
    end

    it 'updates total_score for team2' do
      updater.call
      expect(result2.reload.total_score).to eq(80.0)
    end
  end

  context 'when team has no result' do
    let(:team_no_result) { create(:team, league: league) }

    before { team_no_result }

    it 'does not raise an error' do
      expect { updater.call }.not_to raise_error
    end
  end
end
