# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/tours')
Rake::Task.define_task(:environment)

RSpec.describe 'tours rake tasks' do
  def reenable(task_name)
    Rake::Task[task_name].reenable
  end

  describe 'tours:generate_lineups' do
    before { reenable('tours:generate_lineups') }

    context 'when there is a locked tour with lineups_generated: false' do
      let!(:pending_tour) { create(:locked_tour, lineups_generated: false) }

      before { allow(Tours::LineupGenerator).to receive(:call) }

      it 'calls LineupGenerator for that tour' do
        Rake::Task['tours:generate_lineups'].invoke
        expect(Tours::LineupGenerator).to have_received(:call).with(pending_tour)
      end
    end

    context 'when there is a locked tour with lineups_generated: true' do
      before do
        create(:locked_tour, lineups_generated: true)
        allow(Tours::LineupGenerator).to receive(:call)
      end

      it 'does not call LineupGenerator' do
        Rake::Task['tours:generate_lineups'].invoke
        expect(Tours::LineupGenerator).not_to have_received(:call)
      end
    end

    context 'when there is a set_lineup tour' do
      before do
        create(:set_lineup_tour, lineups_generated: false)
        allow(Tours::LineupGenerator).to receive(:call)
      end

      it 'does not call LineupGenerator' do
        Rake::Task['tours:generate_lineups'].invoke
        expect(Tours::LineupGenerator).not_to have_received(:call)
      end
    end

    context 'when lock file is already held' do
      let(:lock_file) { Rails.root.join('tmp/generate_lineups.lock') }

      before do
        create(:locked_tour, lineups_generated: false)
        allow(Tours::LineupGenerator).to receive(:call)
      end

      it 'skips execution' do
        File.open(lock_file, File::RDWR | File::CREAT, 0o644) do |f|
          f.flock(File::LOCK_EX)
          Rake::Task['tours:generate_lineups'].invoke
        end
        expect(Tours::LineupGenerator).not_to have_received(:call)
      end
    end
  end

  describe 'tours:live_inject' do
    let(:tournament) { create(:tournament, live_scores_enabled: true) }
    let(:t_round) { create(:tournament_round, tournament: tournament) }

    before do
      create(:locked_tour, tournament_round: t_round)
      reenable('tours:live_inject')
      allow(Tours::LiveInjector).to receive(:call)
        .and_return({ candidates: 1, with_data: 1, failures: 0 })
      allow(Scores::ScrapeAlert).to receive(:call)
      allow(Standings::Updater).to receive(:call)
    end

    it 'injects the scores of rounds in play' do
      Rake::Task['tours:live_inject'].invoke

      expect(Tours::LiveInjector).to have_received(:call).with(t_round, budget: anything)
    end

    # FotMob counts unfinished matches in its table, so the live pass is when the table moves.
    it 'refreshes the table of every tournament in play' do
      Rake::Task['tours:live_inject'].invoke

      expect(Standings::Updater).to have_received(:call).with(tournament, season: t_round.season)
    end

    it 'asks for each tournament once even with several rounds in play' do
      create(:locked_tour, tournament_round: create(:tournament_round, tournament: tournament))

      Rake::Task['tours:live_inject'].invoke

      expect(Standings::Updater).to have_received(:call).once
    end

    context 'without a round in play' do
      before { Tour.find_each { |tour| tour.update(status: :set_lineup) } }

      it 'touches no table' do
        Rake::Task['tours:live_inject'].invoke

        expect(Standings::Updater).not_to have_received(:call)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
