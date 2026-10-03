require 'rails_helper'

RSpec.describe 'tournaments/_tournament_matches' do
  subject(:html) { render partial: 'tournaments/tournament_matches', locals: { matches: [fixture] } }

  let(:round) { create(:tournament_round) }
  let(:fixture) do
    create(:tournament_match, tournament_round: round, host_club: create(:club), guest_club: create(:club),
                              host_score: host_score, guest_score: guest_score, status: status,
                              date: 'SEP 19, 2026', time: '16:00')
  end
  let(:status) { :scheduled }

  before { without_partial_double_verification { allow(view).to receive(:current_user).and_return(nil) } }

  context 'with a score' do
    let(:host_score) { 1 }
    let(:guest_score) { 0 }

    it 'shows the score' do
      expect(html).to include('1:0')
    end
  end

  context 'without a score' do
    let(:host_score) { nil }
    let(:guest_score) { nil }

    it 'shows the kickoff time instead' do
      expect(html).to match(/\d{2}:\d{2}/)
    end
  end

  # A 0-0 is a real score: `if match.host_score` has to treat zero as present, or a goalless live
  # match would fall back to showing its kickoff time.
  context 'with a goalless live match' do
    let(:host_score) { 0 }
    let(:guest_score) { 0 }
    let(:status) { :live }

    it 'shows the score rather than the kickoff time' do
      expect(html).to include('0:0')
    end

    it 'flags the cell as live, which is what colours the result red' do
      expect(html).to include('round-tournament-match-cell-result--live')
    end
  end
end
