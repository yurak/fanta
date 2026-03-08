RSpec.describe Audit::CsvWriter do
  subject(:writer) { described_class.new(tournament_match, players) }

  let(:tournament_match) { create(:tournament_match) }
  let(:players) do
    { 'player_one' => { played_minutes: 67, rating: '6.9' },
      'player_two' => { played_minutes: 90, rating: '7.5' } }
  end

  let(:csv) { instance_double(CSV) }

  before do
    allow(CSV).to receive(:open).and_yield(csv)
    allow(csv).to receive(:<<)
  end

  describe '#call' do
    it 'writes header with tournament name' do
      writer.call
      expect(csv).to have_received(:<<).with(array_including(a_string_including(tournament_match.tournament_round.tournament.name)))
    end

    it 'writes header with round id' do
      writer.call
      expect(csv).to have_received(:<<).with(array_including(a_string_including(tournament_match.tournament_round.id.to_s)))
    end

    it 'writes header with host and guest club names' do
      writer.call
      expect(csv).to have_received(:<<).with(array_including(
                                               a_string_including(tournament_match.host_club.name,
                                                                  tournament_match.guest_club.name)
                                             ))
    end

    it 'writes a row for each player' do
      writer.call
      players.each_value do |player_data|
        expect(csv).to have_received(:<<).with([player_data])
      end
    end

    context 'with empty players' do
      let(:players) { {} }

      it 'writes only the header row' do
        writer.call
        expect(csv).to have_received(:<<).once
      end
    end

    context 'with a national match' do
      let(:tournament) { create(:tournament, :with_national_teams) }
      let(:tournament_match) { create(:national_match, tournament_round: create(:tournament_round, tournament: tournament)) }

      it 'writes header with host and guest national team names' do
        writer.call
        expect(csv).to have_received(:<<).with(array_including(
                                                 a_string_including(tournament_match.host_team.name,
                                                                    tournament_match.guest_team.name)
                                               ))
      end
    end
  end
end
