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
      expect(TelegramBot::Sender).to have_received(:call).with(user, anything)
    end

    it 'message contains tour number' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(tour.number.to_s))
    end

    it 'message contains league name' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(league.name))
    end

    it 'message contains tour emoji' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('⚽️'))
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
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('🛒'))
    end

    it 'message contains round number' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(auction_round.number.to_s))
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
    before { create(:auction, league: league, status: :sales, deadline: 3.hours.from_now) }

    it { expect(notifier.call).to be_truthy }

    it 'message contains sales emoji' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('💸'))
    end

    it 'message contains league name' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including(league.name))
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
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('Kyiv'))
    end

    it 'contains #schedule footer' do
      notifier.call
      expect(TelegramBot::Sender).to have_received(:call).with(user, a_string_including('#schedule'))
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
        user_no_locale, a_string_including('UTC')
      )
    end
  end
end
