# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'calendar:extend_tournament' do
  before do
    Rake.application.rake_require('tasks/calendar')
    Rake::Task.define_task(:environment)
    Rake::Task['calendar:extend_tournament'].reenable
  end

  let(:tournament) { create(:tournament, :with_36_rounds) }

  context 'when tournament has active leagues with existing tours' do
    let!(:active_league) { create(:league, :with_ten_teams, status: :active, tournament: tournament) }
    let!(:archived_league) { create(:league, :with_ten_teams, status: :archived, tournament: tournament) }

    before { CalendarCreator.call(active_league.id, 30) }

    it 'extends active league tours' do
      Rake::Task['calendar:extend_tournament'].invoke(tournament.id, 6)
      expect(active_league.reload.tours.count).to eq(36)
    end

    it 'does not extend archived league tours' do
      Rake::Task['calendar:extend_tournament'].invoke(tournament.id, 6)
      expect(archived_league.reload.tours.count).to eq(0)
    end
  end

  context 'when tournament has no active leagues' do
    let!(:archived_league) { create(:league, :with_ten_teams, status: :archived, tournament: tournament) }

    before { CalendarCreator.call(archived_league.id, 30) }

    it 'does not extend archived leagues' do
      Rake::Task['calendar:extend_tournament'].invoke(tournament.id, 6)
      expect(archived_league.reload.tours.count).to eq(30)
    end
  end

  context 'when CalendarExtender fails for a league' do
    let!(:active_league) { create(:league, :with_ten_teams, status: :active, tournament: tournament) }

    before do
      CalendarCreator.call(active_league.id, 30)
      allow(CalendarExtender).to receive(:call).and_return(false)
    end

    it 'rolls back and does not extend tours' do
      Rake::Task['calendar:extend_tournament'].invoke(tournament.id, 6)
      expect(active_league.reload.tours.count).to eq(30)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
