# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::DdlBroadcaster do
  subject(:broadcaster) { described_class.new }

  let(:league) { create(:active_league) }

  before { allow(Notifications::Creator).to receive(:call) }

  def tour_with_deadline(deadline, status: :set_lineup_tour, tour_league: league)
    round = create(:tournament_round, tournament: tour_league.tournament, deadline: deadline)
    create(status, league: tour_league, tournament_round: round)
  end

  context 'when there are no tours at all' do
    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when the tour has no deadline' do
    before { tour_with_deadline(nil) }

    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  # The point of the rework: the reminder is pinned to the deadline, so a round closing at 15:15 is
  # announced at 10:15 rather than at whatever hour the cron happens to run.
  described_class::REMINDER_HOURS.each do |hours|
    context "when the deadline is exactly #{hours} hours away" do
      let!(:tour) { tour_with_deadline(hours.hours.from_now) }

      it "records the #{hours}h reminder" do
        broadcaster.call

        expect(Notifications::Creator).to have_received(:call)
          .with(notifiable: tour, kind: :"tour_ddl_#{hours}h")
      end

      it 'records nothing else' do
        broadcaster.call

        expect(Notifications::Creator).to have_received(:call).once
      end
    end
  end

  context 'when the deadline is between two offsets' do
    before { tour_with_deadline(4.hours.from_now) }

    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  # The window is wider than the cron step, so a single missed pass does not lose the reminder.
  context 'when the pass runs a few minutes late' do
    let!(:tour) { tour_with_deadline(5.hours.from_now - 6.minutes) }

    it 'still records it' do
      broadcaster.call

      expect(Notifications::Creator).to have_received(:call)
        .with(notifiable: tour, kind: :tour_ddl_5h)
    end
  end

  context 'when the deadline has already passed' do
    before { tour_with_deadline(10.minutes.ago) }

    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when the tour is not open for lineups' do
    before { tour_with_deadline(3.hours.from_now, status: :locked_tour) }

    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when the league is not active' do
    before { tour_with_deadline(3.hours.from_now, tour_league: create(:league)) }

    it 'records nothing' do
      broadcaster.call

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end
