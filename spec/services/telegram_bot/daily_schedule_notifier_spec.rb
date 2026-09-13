# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::DailyScheduleNotifier do
  subject(:notifier) { described_class.new(user) }

  let(:user)   { create(:user, :with_profile, time_zone: 'Kyiv', locale: 'ua') }
  let(:league) { create(:active_league) }

  before do
    create(:team, user: user, league: league)
    allow(TelegramBot::Sender).to receive(:call).and_return(true)
  end

  # The message is HTML now, and FFaker company names carry an apostrophe often enough (~2.6%) that
  # comparing against the raw name is a flake waiting for CI.
  def escaped_league_name
    CGI.escapeHTML(league.name)
  end

  context 'when there are no deadlines in next 24 hours' do
    it { expect(notifier.call).to be(false) }

    it 'does not call Sender' do
      notifier.call
      expect(TelegramBot::Sender).not_to have_received(:call)
    end
  end

  context 'when user has no teams with leagues' do
    before { create(:team, user: user, league: nil) }

    it { expect(notifier.call).to be(false) }
  end

  context 'with a tour deadline within 24 hours' do
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }

    before { tour }

    it { expect(notifier.call).to be_truthy }

    it 'calls Sender with the user' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, anything, any_args)
    end

    it 'message contains tour number' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(tour.number.to_s), any_args)
    end

    it 'message contains league name' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(escaped_league_name), any_args)
    end

    it 'message contains tour emoji' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('⚽️'), any_args)
    end

    it 'links the round to its tour page' do
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(
        user, a_string_including("<a href=\"#{Rails.application.routes.url_helpers.tour_url(tour)}\">"), any_args
      )
    end

    # The link only renders as one when Telegram is told to parse the markup.
    it 'asks Telegram to parse the markup' do
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(
        user, anything, parse_mode: 'HTML', disable_web_page_preview: true
      )
    end
  end

  context 'with a lineup status' do
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }
    let(:team) { user.teams.first }

    before { tour }

    it 'marks a tour the user has no lineup for' do
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('❌'), any_args)
    end

    it 'marks a tour the user has already set' do
      create(:lineup, tour: tour, team: team)

      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('✅'), any_args)
    end

    # Another manager's lineup for the same tour must not count as this user's.
    it 'ignores a lineup of another team' do
      create(:lineup, tour: tour, team: create(:team, league: league))

      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('❌'), any_args)
    end
  end

  # HTML parse mode makes an ampersand in a league name a parse error, so it has to be escaped.
  context 'with a league name that carries HTML-special characters' do
    let(:league) { create(:active_league, name: 'Bravery&Stupidity') }
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }

    before { tour }

    it 'escapes the name' do
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(
        user, a_string_including('Bravery&amp;Stupidity'), any_args
      )
    end
  end

  context 'with a tour deadline beyond 24 hours' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 30.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it { expect(notifier.call).to be(false) }
  end

  context 'with a non-set_lineup tour deadline within 24 hours' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now)
      create(:locked_tour, league: league, tournament_round: tr)
    end

    it { expect(notifier.call).to be(false) }
  end

  context 'with an active auction round deadline within 24 hours' do
    let(:auction)       { create(:auction, league: league) }
    let(:auction_round) { create(:auction_round, auction: auction, deadline: 3.hours.from_now) }

    before { create(:auction_bid, auction_round: auction_round, team: user.teams.find_by(league: league)) }

    it { expect(notifier.call).to be_truthy }

    it 'message contains auction round emoji' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('🛒'), any_args)
    end

    it 'message contains round number' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(auction_round.number.to_s), any_args)
    end

    it 'links the round to its auction page' do
      link = "<a href=\"#{Rails.application.routes.url_helpers.auction_round_url(auction_round)}\">"
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(link), any_args)
    end
  end

  context 'with an active auction round but no bid for the user team' do
    before do
      auction = create(:auction, league: league)
      create(:auction_round, auction: auction, deadline: 3.hours.from_now)
    end

    it { expect(notifier.call).to be(false) }
  end

  context 'with a closed auction round deadline within 24 hours' do
    before do
      auction = create(:auction, league: league)
      team = create(:team, user: user, league: league)
      round = create(:closed_auction_round, auction: auction, deadline: 3.hours.from_now)
      create(:auction_bid, auction_round: round, team: team)
    end

    it { expect(notifier.call).to be(false) }
  end

  context 'with an auction in sales status with deadline within 24 hours' do
    let!(:auction) { create(:auction, league: league, status: :sales, deadline: 3.hours.from_now) }

    it { expect(notifier.call).to be_truthy }

    it 'links the sales period to its page' do
      link = "<a href=\"#{Rails.application.routes.url_helpers.sales_league_auction_url(league, auction)}\">"
      notifier.call

      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(link), any_args)
    end

    it 'message contains sales emoji' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('💸'), any_args)
    end

    it 'message contains league name' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(escaped_league_name), any_args)
    end
  end

  context 'with a deadline belonging to another league not linked to user' do
    before do
      other_league = create(:active_league)
      tr = create(:tournament_round, tournament: other_league.tournament, deadline: 3.hours.from_now)
      create(:set_lineup_tour, league: other_league, tournament_round: tr)
    end

    it { expect(notifier.call).to be(false) }
  end

  context 'with multiple deadlines at different times' do
    let(:early_time) { user.local_time(2.hours.from_now, '%H:%M') }
    let(:late_time)  { user.local_time(8.hours.from_now, '%H:%M') }
    let(:tour_early) do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 2.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end
    let(:tour_late) do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 8.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    before { [tour_early, tour_late] }

    it 'sends one message' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).once
    end

    it 'message lists earlier deadline before later deadline' do
      captured_msg = nil
      allow(TelegramBot::Sender).to receive(:call) { |_, msg| captured_msg = msg }
      notifier.call
      expect(captured_msg.index(early_time)).to be < captured_msg.index(late_time)
    end
  end

  context 'when checking message structure' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'header contains timezone' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('Kyiv'), any_args)
    end

    it 'contains #schedule footer' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('#schedule'), any_args)
    end
  end

  context 'when user has no locale and default timezone' do
    subject(:notifier) { described_class.new(user_no_locale) }

    let(:user_no_locale) { create(:user, :with_profile, time_zone: 'UTC', locale: nil) }

    before do
      create(:team, user: user_no_locale, league: league)
      tr = create(:tournament_round, tournament: league.tournament, deadline: 3.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'uses UTC timezone in header' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(
        user_no_locale, a_string_including('UTC'), any_args
      )
    end
  end
end
