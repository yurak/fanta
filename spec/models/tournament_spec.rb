RSpec.describe Tournament, type: :model do
  subject(:tournament) { create(:tournament) }

  describe 'Associations' do
    it { is_expected.to have_many(:article_tags).dependent(:destroy) }
    it { is_expected.to have_many(:clubs).dependent(:destroy) }
    it { is_expected.to have_many(:leagues).dependent(:destroy) }
    it { is_expected.to have_many(:links).dependent(:destroy) }
    it { is_expected.to have_many(:national_teams).dependent(:destroy) }
    it { is_expected.to have_many(:tournament_rounds).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :code }
    it { is_expected.to validate_uniqueness_of :code }
  end

  describe '#logo_path' do
    context 'when logo does not exist' do
      it 'returns default path' do
        expect(tournament.logo_path).to eq('tournaments/uefa.png')
      end
    end

    context 'when logo exists' do
      let(:code) { tournament.code }
      let(:file_path) { "app/assets/images/tournaments/#{code}.png" }

      it 'returns path to tournament logo' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)

        expect(tournament.logo_path).to eq("tournaments/#{code}.png")
      end
    end
  end

  describe '#national?' do
    context 'without national teams' do
      it 'returns false' do
        expect(tournament.national?).to eq(false)
      end
    end

    context 'with national teams' do
      it 'returns true' do
        create_list(:national_team, 2, tournament: tournament)

        expect(tournament.national?).to eq(true)
      end
    end
  end
end
