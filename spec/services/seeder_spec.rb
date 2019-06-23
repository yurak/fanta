RSpec.describe Seeder do
  context 'create team' do
    subject { described_class.new(team_name: 'raky').create_team }

    before do
      Seeder.new(objects_name: 'clubs').save
      Seeder.new(objects_name: 'teams').save
      Seeder.new(objects_name: 'positions').save
    end

    it 'creates team' do
      expect(subject.size).to eq 25
    end

    it 'team is raky' do
      expect(subject.map { |t| t.team.name }.uniq).to eq ['raky']
    end

    it 'has 4 Dd s' do
      expect(subject.joins(:positions).where(positions: { name: 'Dd' }).count).to eq 4
    end
  end
end
