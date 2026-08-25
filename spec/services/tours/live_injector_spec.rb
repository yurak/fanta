require 'rails_helper'

RSpec.describe Tours::LiveInjector do
  subject(:inject) { described_class.call(round) }

  let(:tournament) { create(:tournament, source: :fotmob) }
  let(:round)      { create(:tournament_round, tournament: tournament) }
  let(:league)     { create(:league, tournament: tournament) }
  let!(:tour)      { create(:tour, league: league, tournament_round: round, status: :locked) }

  let(:kickoff) { 1.hour.ago.utc }

  def create_match(**attrs)
    defaults = { tournament_round: round, page_url: '/matches/x', status: :scheduled,
                 date: kickoff.strftime('%b %e, %Y'), time: kickoff.strftime('%H:%M') }
    create(:tournament_match, **defaults, **attrs)
  end

  before do
    allow(Scores::Injectors::FotmobMatch).to receive(:call)
    allow(Scores::PositionMalus::Updater).to receive(:call)
    allow(Lineups::Updater).to receive(:call)
  end

  it 'injects live scores for an in-progress match' do
    match = create_match
    inject

    expect(Scores::Injectors::FotmobMatch).to have_received(:call).with(match, run_mode: :live)
  end

  it 'recomputes position malus for the round tours' do
    create_match
    inject

    expect(Scores::PositionMalus::Updater).to have_received(:call).with(tour)
  end

  it 'recomputes lineups for the round tours' do
    create_match
    inject

    expect(Lineups::Updater).to have_received(:call).with(tour)
  end

  it 'skips finished matches' do
    create_match(status: :finished)
    inject

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
  end

  it 'skips matches outside the live window' do
    old = 5.hours.ago.utc
    create_match(date: old.strftime('%b %e, %Y'), time: old.strftime('%H:%M'))
    inject

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:call)
  end

  it 'does not recompute when there are no live matches' do
    inject

    expect(Lineups::Updater).not_to have_received(:call)
  end
end
