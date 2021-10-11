RSpec.describe Scores::Injectors::Calcio do
  subject(:injector) { described_class.new(tournament_round: tournament_round) }

  let(:tournament_round) { create(:tournament_round, :with_serie_a_tournament, number: 5) }
  let(:host_club) { create(:club, name: 'Salernitana') }
  let(:guest_club) { create(:club, name: 'Verona') }

  describe '#call' do
    context 'with nil tournament round' do
      let(:tournament_round) { nil }

      it { expect(injector.call).to eq(false) }
    end

    context 'when clubs do not exist' do
      let(:player) { create(:player, name: 'Diaz') }
      let(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'does not update round players' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(0)
        end
      end
    end

    context 'when host club and player exist' do
      let(:player) { create(:player, name: 'Gagliolo', club: host_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(5.24)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(90)
        end
      end
    end

    context 'when host club exist and player played more than 90 minutes' do
      let(:player) { create(:player, name: 'Gyomber', club: host_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(5.88)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(90)
        end
      end
    end

    context 'when host club and substituted player exist' do
      let(:player) { create(:player, name: 'Ribery', club: host_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.2)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(88)
        end
      end
    end

    context 'when host club and released player exist' do
      let(:player) { create(:player, name: 'Bonazzoli', club: host_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.04)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(16)
        end
      end
    end

    context 'when host club and player does not play' do
      let(:player) { create(:player, name: 'Obi', club: host_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'does not update round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(0)
        end
      end

      it 'does not update round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(0)
        end
      end
    end

    context 'when guest club and player exist' do
      let(:player) { create(:player, name: 'Hongla', club: guest_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(5.17)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(90)
        end
      end
    end

    context 'when guest club exist and player played more than 90 minutes' do
      let(:player) { create(:player, name: 'Lazovic', club: guest_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(5.83)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(90)
        end
      end
    end

    context 'when guest club and substituted player exist' do
      let(:player) { create(:player, name: 'Kalinic', club: guest_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(7.41)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(56)
        end
      end
    end

    context 'when guest club and released player exist' do
      let(:player) { create(:player, name: 'Simeone', club: guest_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(5.87)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(34)
        end
      end
    end

    context 'when guest club and player does not play' do
      let(:player) { create(:player, name: 'Svoboda', club: guest_club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'does not update round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(0)
        end
      end

      it 'does not update round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(0)
        end
      end
    end

    context 'with tournament match' do
      let!(:tournament_match) do
        create(:tournament_match, tournament_round: tournament_round, host_club: host_club, guest_club: guest_club)
      end

      it 'updates tournament match host score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(tournament_match.reload.host_score).to eq(2)
        end
      end

      it 'updates tournament match guest score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(tournament_match.reload.guest_score).to eq(2)
        end
      end
    end
  end
end
