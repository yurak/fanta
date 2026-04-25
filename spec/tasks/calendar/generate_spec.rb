# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'calendar:generate' do
  before do
    Rake.application.rake_require('tasks/calendar')
    Rake::Task.define_task(:environment)
    Rake::Task['calendar:generate'].reenable
  end

  let(:tournament) { create(:tournament, :with_36_rounds) }
  let(:league) { create(:league, :with_ten_teams, tournament: tournament) }

  def run_task(league_id, tours_count)
    Rake::Task['calendar:generate'].invoke(league_id, tours_count)
  end

  context 'when CalendarCreator succeeds' do
    it 'creates tours for the league' do
      run_task(league.id, 10)
      expect(league.reload.tours.count).to eq(10)
    end

    it 'creates results for the league' do
      run_task(league.id, 10)
      expect(league.reload.results.count).to be_positive
    end

    it 'calls Results::Creator' do
      allow(Results::Creator).to receive(:call).and_call_original
      run_task(league.id, 10)
      expect(Results::Creator).to have_received(:call).with(league.id)
    end
  end

  context 'when CalendarCreator fails' do
    before do
      allow(CalendarCreator).to receive(:call).and_return(false)
      allow(Results::Creator).to receive(:call)
    end

    it 'does not call Results::Creator' do
      run_task(league.id, 10)
      expect(Results::Creator).not_to have_received(:call)
    end

    it 'does not create tours' do
      run_task(league.id, 10)
      expect(league.reload.tours.count).to eq(0)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
