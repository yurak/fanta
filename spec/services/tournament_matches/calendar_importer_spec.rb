require 'rails_helper'

RSpec.describe TournamentMatches::CalendarImporter do
  subject(:import) { described_class.call(tournament) }

  let(:season) { Season.last }
  let(:tournament) { create(:tournament, mode: :mantra, source_id: 47) }
  let(:home) { create(:club, tournament: tournament) }
  let(:away) { create(:club, tournament: tournament) }

  def entry(number:, day:, **overrides)
    id = overrides.fetch(:id, '1')
    { source_match_id: id, round_name: number, page_url: "/matches/#{id}",
      home_name: overrides.fetch(:home_name, home.name), away_name: overrides.fetch(:away_name, away.name),
      kickoff: DateTime.parse("2026-09-#{day}T18:00:00Z").utc, score: overrides[:score] }
  end

  before do
    (1..4).each { |number| create(:tournament_round, tournament: tournament, season: season, number: number) }
    allow(TournamentRounds::FotmobCalendarParser).to receive(:call).and_return(entries)
  end

  context 'with a regular tournament' do
    let(:entries) { [entry(number: 2, day: '08')] }

    it 'creates the match' do
      expect { import }.to change(TournamentMatch, :count).by(1)
    end

    it 'uses the FotMob round number' do
      import

      expect(TournamentMatch.last.tournament_round.number).to eq(2)
    end

    it 'stores the kickoff' do
      import

      expect(TournamentMatch.last).to have_attributes(date: 'SEP  8, 2026', time: '18:00')
    end

    it 'reports what it did' do
      expect(import).to include(created: 1, updated: 0, failed: 0)
    end
  end

  context 'with a fanta tournament' do
    let(:tournament) { create(:tournament, mode: :fanta, eurocup: true, source_id: 42) }
    let(:entries) do
      [entry(number: 1, day: '08', id: 'a'), entry(number: 1, day: '09', id: 'b'),
       entry(number: 2, day: '10', id: 'c'), entry(number: 2, day: '10', id: 'd')]
    end

    it 'gives every kickoff day its own round, ignoring the FotMob round number' do
      import

      expect(TournamentMatch.order(:source_match_id).map { |m| m.tournament_round.number }).to eq([1, 2, 3, 3])
    end

    it 'stores the day-based number as the round name too' do
      import

      expect(TournamentMatch.find_by(source_match_id: 'c').round_name).to eq('3')
    end
  end

  context 'when re-imported' do
    let(:entries) { [entry(number: 1, day: '08', score: '2 - 1')] }

    before { described_class.call(tournament) }

    it 'updates instead of duplicating' do
      expect { import }.not_to change(TournamentMatch, :count)
    end

    it 'counts the row as updated' do
      expect(import).to include(created: 0, updated: 1)
    end

    it 'keeps the score the live injector owns' do
      TournamentMatch.last.update!(host_score: 5, guest_score: 0)
      import

      expect(TournamentMatch.last.host_score).to eq(5)
    end
  end

  context 'with a score on a fresh match' do
    let(:entries) { [entry(number: 1, day: '08', score: '3 - 0')] }

    it 'stores it' do
      import

      expect(TournamentMatch.last).to have_attributes(host_score: 3, guest_score: 0)
    end
  end

  context 'with a club missing from the database' do
    let(:entries) { [entry(number: 1, day: '08', home_name: 'Sabah FK')] }

    it 'does not create a half-empty match' do
      expect { import }.not_to change(TournamentMatch, :count)
    end

    it 'reports the club by name' do
      expect(import[:unknown_clubs]).to eq(['Sabah FK'])
    end

    it 'counts the failure' do
      expect(import).to include(failed: 1)
    end
  end

  context 'when the round does not exist' do
    let(:entries) { [entry(number: 9, day: '08')] }

    it 'skips the match' do
      expect { import }.not_to change(TournamentMatch, :count)
    end

    it 'reports the missing round' do
      expect(import).to include(skipped: 1, missing_rounds: [9])
    end
  end

  context 'when the source returns nothing' do
    let(:entries) { [] }

    it { expect(import).to include(created: 0, updated: 0) }
  end
end
