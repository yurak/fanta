RSpec.describe Scores::Injectors::Calcio do
  subject(:injector) { described_class.new(tournament_round: tournament_round) }

  let(:tournament_round) { create(:tournament_round, :with_serie_a_tournament, number: 5) }

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
      let!(:club) { create(:club, name: 'Milan') }
      let(:player) { create(:player, name: 'Tonali', club: club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.15)
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
      let!(:club) { create(:club, name: 'Milan') }
      let(:player) { create(:player, name: 'Kalulu', club: club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.86)
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
      let!(:club) { create(:club, name: 'Milan') }
      let(:player) { create(:player, name: 'Diaz', club: club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.64)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(81)
        end
      end
    end

    context 'when host club and released player exist' do
      let!(:club) { create(:club, name: 'Milan') }
      let(:player) { create(:player, name: 'Tomori', club: club) }
      let!(:round_player) { create(:round_player, tournament_round: tournament_round, player: player) }

      it 'updates round player score' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.score).to eq(6.02)
        end
      end

      it 'updates round player played_minutes' do
        VCR.use_cassette 'injector_calcio_scores' do
          injector.call

          expect(round_player.reload.played_minutes).to eq(31)
        end
      end
    end

    context 'when host club and player does not play' do
      let!(:club) { create(:club, name: 'Milan') }
      let(:player) { create(:player, name: 'Conti', club: club) }
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
      let!(:club) { create(:club, name: 'Verona') }
      let(:player) { create(:player, name: 'Hongla', club: club) }
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
      let!(:club) { create(:club, name: 'Verona') }
      let(:player) { create(:player, name: 'Lazovic', club: club) }
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
      let!(:club) { create(:club, name: 'Verona') }
      let(:player) { create(:player, name: 'Kalinic', club: club) }
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
      let!(:club) { create(:club, name: 'Verona') }
      let(:player) { create(:player, name: 'Simeone', club: club) }
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
      let!(:club) { create(:club, name: 'Verona') }
      let(:player) { create(:player, name: 'Svoboda', club: club) }
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
  end
end
