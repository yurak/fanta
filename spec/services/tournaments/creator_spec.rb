RSpec.describe Tournaments::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:tournaments_config) do
      {
        'spec_regular' => { 'name' => 'Spec Regular', 'eurocup' => false },
        'spec_eurocup' => { 'name' => 'Spec Eurocup', 'eurocup' => true  }
      }
    end

    before do
      allow(YAML).to receive(:load_file).and_return(tournaments_config)
    end

    it 'creates a tournament for each entry in config' do
      expect { creator.call }.to change(Tournament, :count).by(2)
    end

    it 'sets the correct name' do
      creator.call
      expect(Tournament.find_by(code: 'spec_regular').name).to eq('Spec Regular')
    end

    it 'sets the correct code' do
      creator.call
      expect(Tournament.pluck(:code)).to include('spec_regular', 'spec_eurocup')
    end

    it 'sets eurocup false for regular tournament' do
      creator.call
      expect(Tournament.find_by(code: 'spec_regular').eurocup).to be(false)
    end

    it 'sets eurocup true for eurocup tournament' do
      creator.call
      expect(Tournament.find_by(code: 'spec_eurocup').eurocup).to be(true)
    end

    context 'with real tournaments.yml' do
      before do
        allow(YAML).to receive(:load_file).and_call_original
        Tournament.delete_all
      end

      let(:config) { YAML.load_file(Rails.root.join('config/mantra/tournaments.yml')) }

      it 'creates all tournaments from config' do
        expect { creator.call }.to change(Tournament, :count).by(config.size)
      end

      it 'creates tournaments with correct codes' do
        creator.call
        expect(Tournament.pluck(:code)).to match_array(config.keys)
      end

      it 'creates eurocup tournaments correctly' do
        creator.call
        eurocup_codes = config.select { |_, v| v['eurocup'] }.keys
        expect(Tournament.where(eurocup: true).pluck(:code)).to match_array(eurocup_codes)
      end
    end
  end
end
