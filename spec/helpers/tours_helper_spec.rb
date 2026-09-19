RSpec.describe ToursHelper do
  describe '#time_to_deadline(time_hash)' do
    let(:time_hash) { nil }

    context 'without time_hash' do
      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('')
      end
    end

    context 'with time_hash' do
      let(:time_hash) { { days: 3, minutes: 45 } }

      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('3d 45m left')
      end
    end
  end

  describe '#round_opponents' do
    subject(:opponents) { helper.round_opponents(round) }

    let(:round) { create(:tournament_round) }
    let(:host) { create(:club) }
    let(:guest) { create(:club) }

    before { create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest) }

    it 'maps the home club to its visitor' do
      expect(opponents[host.id]).to eq(guest)
    end

    it 'maps the away club to its host' do
      expect(opponents[guest.id]).to eq(host)
    end

    it 'leaves out a club that does not play this round' do
      expect(opponents[create(:club).id]).to be_nil
    end
  end

  describe '#live_standing_results' do
    subject(:results) { helper.live_standing_results(tournament, season.id) }

    let(:season) { create(:season) }
    let(:tournament) { create(:tournament) }
    let(:round) { create(:tournament_round, tournament: tournament, season: season) }
    let(:host) { create(:club) }
    let(:guest) { create(:club) }

    context 'with a live match the home club is leading' do
      before do
        create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                  host_score: 2, guest_score: 1, status: :live)
      end

      it 'marks the leader as winning' do
        expect(results[host.id]).to eq('win')
      end

      it 'marks the other club as losing' do
        expect(results[guest.id]).to eq('loss')
      end
    end

    # A match that has just kicked off has no goals yet, which is a draw, not "no result".
    context 'with a live match still goalless' do
      before do
        create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                  host_score: nil, guest_score: nil, status: :live)
      end

      it 'marks both clubs as drawing' do
        expect(results.values).to all(eq('draw'))
      end
    end

    context 'with a match that has finished' do
      before do
        create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                  host_score: 2, guest_score: 1, status: :finished)
      end

      it 'marks nobody' do
        expect(results).to be_empty
      end
    end

    context 'with a live match in another season' do
      before do
        other_round = create(:tournament_round, tournament: tournament, season: create(:season))
        create(:tournament_match, tournament_round: other_round, host_club: host, guest_club: guest,
                                  host_score: 1, guest_score: 0, status: :live)
      end

      it 'marks nobody' do
        expect(results).to be_empty
      end
    end

    context 'with a live match in another tournament' do
      before do
        other_round = create(:tournament_round, tournament: create(:tournament), season: season)
        create(:tournament_match, tournament_round: other_round, host_club: host, guest_club: guest,
                                  host_score: 1, guest_score: 0, status: :live)
      end

      it 'marks nobody' do
        expect(results).to be_empty
      end
    end
  end
end
