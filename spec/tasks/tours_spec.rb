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
end
# rubocop:enable RSpec/DescribeClass
