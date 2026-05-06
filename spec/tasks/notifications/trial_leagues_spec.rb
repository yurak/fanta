# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'notifications:trial_leagues' do
  let(:enabled_user) { create(:user) }
  let(:disabled_user) { create(:user) }
  let(:user_without_profile) { create(:user) }
  let(:joined_user) { create(:user) }

  before do
    Rake.application.rake_require('tasks/notifications')
    Rake::Task.define_task(:environment)
    Rake::Task['notifications:trial_leagues'].reenable
    allow(TelegramBot::Sender).to receive(:call)

    setup_trial_tournaments
    user_without_profile
    create(:user_profile, user: enabled_user, bot_enabled: true)
    create(:user_profile, user: disabled_user, bot_enabled: false)
    create(:user_profile, user: joined_user, bot_enabled: true)
    create(:join, user: joined_user, tournament: Tournament.find(1))
  end

  def run_task
    Rake::Task['notifications:trial_leagues'].invoke
  end

  def setup_trial_tournaments
    (1..5).each do |id|
      tournament = Tournament.find_or_initialize_by(id: id)
      tournament.update!(name: "Tournament #{id}", code: "trial_#{id}", icon: "Icon#{id}")
    end
  end

  it 'sends recruitment notifications to Telegram-enabled users without joins' do
    run_task

    expect(TelegramBot::Sender).to have_received(:call).with(enabled_user, include('Icon1 Icon2 Icon3 Icon4 Icon5'))
  end

  it 'includes recruitment copy in the Telegram message' do
    run_task

    expect(TelegramBot::Sender).to have_received(:call).with(enabled_user, include('Участь в пробних лігах безкоштовна'))
  end

  it 'skips users with disabled Telegram notifications' do
    run_task

    expect(TelegramBot::Sender).not_to have_received(:call).with(disabled_user, anything)
  end

  it 'skips users without profile' do
    run_task

    expect(TelegramBot::Sender).not_to have_received(:call).with(user_without_profile, anything)
  end

  it 'skips users with joins' do
    run_task

    expect(TelegramBot::Sender).not_to have_received(:call).with(joined_user, anything)
  end

  it 'prints delivery summary' do
    expect { run_task }.to output("Done. Sent: 1, skipped (no Telegram): 2\n").to_stdout
  end
end
# rubocop:enable RSpec/DescribeClass
