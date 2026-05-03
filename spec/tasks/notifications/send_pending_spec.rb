# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'notifications:send_pending' do
  before do
    Rake.application.rake_require('tasks/notifications')
    Rake::Task.define_task(:environment)
    Rake::Task['notifications:send_pending'].reenable
    allow(Notifications::SendPendingJob).to receive(:perform_now)
  end

  def run_task
    Rake::Task['notifications:send_pending'].invoke
  end

  it 'calls Notifications::SendPendingJob' do
    run_task
    expect(Notifications::SendPendingJob).to have_received(:perform_now)
  end
end
# rubocop:enable RSpec/DescribeClass
