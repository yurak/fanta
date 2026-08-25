require 'rails_helper'

RSpec.describe Tours::Dashboard do
  subject(:result) { described_class.call }

  let(:tournament) { create(:tournament) }
  let(:round)      { create(:tournament_round, tournament: tournament) }

  def create_tour(status, updated_at: nil)
    tour = create(:tour, tournament_round: round, status: status)
    tour.update_column(:updated_at, updated_at) if updated_at # rubocop:disable Rails/SkipsModelValidations
    tour
  end

  def tournament_entry
    result.find { |entry| entry[:tournament].id == tournament.id }
  end

  context 'with active tours in a round' do
    before do
      create_tour(:postponed)
      create_tour(:postponed)
      create_tour(:locked)
      create_tour(:set_lineup)
    end

    it 'counts tours per status for the round' do
      counts = tournament_entry[:rounds].find { |entry| entry[:round].id == round.id }[:counts]

      expect(counts).to eq('set_lineup' => 1, 'locked' => 1, 'postponed' => 2)
    end
  end

  context 'with only inactive tours' do
    before { create_tour(:inactive) }

    it 'shows the round as the first not-opened tour' do
      expect(tournament_entry[:rounds].first[:counts]).to eq('inactive' => 1)
    end
  end

  context 'with inactive tours across several rounds' do
    let(:later_round) { create(:tournament_round, tournament: tournament, number: round.number + 1) }

    before do
      create_tour(:inactive)
      create(:tour, tournament_round: later_round, status: :inactive)
    end

    it 'includes only the earliest not-opened round' do
      expect(tournament_entry[:rounds].map { |entry| entry[:round].id }).to eq([round.id])
    end
  end

  context 'with recently closed tours' do
    before { create_tour(:closed, updated_at: 1.day.ago) }

    it 'includes them with a closed count' do
      expect(tournament_entry[:rounds].first[:counts]).to eq('closed' => 1)
    end
  end

  context 'with tours closed long ago' do
    before { create_tour(:closed, updated_at: 10.days.ago) }

    it 'excludes them' do
      expect(tournament_entry).to be_nil
    end
  end
end
