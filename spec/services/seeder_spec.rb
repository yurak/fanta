RSpec.describe Seeder do
  # context 'create team' do
  #   subject { described_class.new(team_name: 'sx').create_team }
  #
  #   before do
  #     Seeder.new(objects_name: 'clubs').save
  #     Seeder.new(objects_name: 'teams').save
  #     Seeder.new(objects_name: 'positions').save
  #   end
  #
  #   it 'creates team' do
  #     expect(subject.size).to eq 25
  #   end
  #
  #   it 'team is sx' do
  #     expect(subject.map { |t| t.team.name }.uniq).to eq ['sx']
  #   end
  #
  #   it 'has 4 Dd s' do
  #     expect(subject.joins(:positions).where(positions: { name: 'Dd' }).count).to eq 2
  #   end
  # end
end
