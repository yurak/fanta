require 'rails_helper'

RSpec.describe Tours::ScheduleRefresher do
  let(:round) { create(:tournament_round) }

  before { allow(Scores::Injectors::FotmobMatch).to receive(:call) }

  it 'runs a schedule-only injector pass for each match with a page url' do
    match = create(:tournament_match, tournament_round: round, page_url: '/matches/x')
    described_class.call(round)

    expect(Scores::Injectors::FotmobMatch).to have_received(:call).with(match, run_mode: :schedule)
  end

  it 'skips matches without a page url' do
    create(:tournament_match, tournament_round: round, page_url: '')
    described_class.call(round)

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
  end

  it 'skips finished matches' do
    create(:tournament_match, tournament_round: round, page_url: '/matches/x', status: :finished)
    described_class.call(round)

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
  end

  it 'stamps the round so it is not refreshed again' do
    create(:tournament_match, tournament_round: round, page_url: '/matches/x')
    described_class.call(round)

    expect(round.reload.schedule_refreshed_at).to be_present
  end
end
