require 'rails_helper'

RSpec.describe Tours::LiveInjector do
  subject(:inject) { described_class.call(round) }

  let(:tournament) { create(:tournament, source: :fotmob) }
  let(:round)      { create(:tournament_round, tournament: tournament) }
  let(:league)     { create(:league, tournament: tournament) }
  let!(:tour)      { create(:tour, league: league, tournament_round: round, status: :locked) }
  let(:kickoff)    { 1.hour.ago.utc }
  let(:injector) do
    instance_double(Scores::Injectors::FotmobMatch, call: true, data_available?: true, scrape_health_failure?: false)
  end

  def create_match(**attrs)
    defaults = { tournament_round: round, page_url: '/matches/x', status: :scheduled,
                 date: kickoff.strftime('%b %e, %Y'), time: kickoff.strftime('%H:%M') }
    create(:tournament_match, **defaults, **attrs)
  end

  before do
    allow(Scores::Injectors::FotmobMatch).to receive(:new).and_return(injector)
    allow(Scores::PositionMalus::Updater).to receive(:call)
    allow(Lineups::Updater).to receive(:call)
  end

  it 'injects live scores for an in-progress match' do
    match = create_match
    inject

    expect(Scores::Injectors::FotmobMatch).to have_received(:new).with(match, run_mode: :live)
  end

  it 'runs the injector' do
    create_match
    inject

    expect(injector).to have_received(:call)
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

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:new)
  end

  it 'skips matches outside the live window' do
    old = 5.hours.ago.utc
    create_match(date: old.strftime('%b %e, %Y'), time: old.strftime('%H:%M'))
    inject

    expect(Scores::Injectors::FotmobMatch).not_to have_received(:new)
  end

  it 'keeps polling an already-live match whose kickoff is long past' do
    old = 6.hours.ago.utc
    match = create_match(status: :live, date: old.strftime('%b %e, %Y'), time: old.strftime('%H:%M'))
    inject

    expect(Scores::Injectors::FotmobMatch).to have_received(:new).with(match, run_mode: :live)
  end

  it 'does not recompute when there are no live matches' do
    inject

    expect(Lineups::Updater).not_to have_received(:call)
  end

  it 'returns the candidate, with-data and failure counts' do
    create_match

    expect(described_class.call(round)).to eq(candidates: 1, with_data: 1, failures: 0)
  end

  it 'counts a scrape health failure' do
    create_match
    allow(injector).to receive_messages(data_available?: false, scrape_health_failure?: true)

    expect(described_class.call(round)).to eq(candidates: 1, with_data: 0, failures: 1)
  end
end
