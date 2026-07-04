# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'
require 'csv'

Rake.application.rake_require('tasks/club_transfers')
Rake::Task.define_task(:environment)

RSpec.describe 'club_transfers:fetch_data rake task' do
  let(:tournament) { create(:tournament) }
  let(:old_club) { create(:club, tournament: tournament) }
  let(:new_club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: old_club, tm_id: 28_003) }
  let(:tm_data) do
    { tm_club_id: '283', club_id: new_club.id, club_joined_on: '2024-07-30', contract_until: '2028-06-30', loan: false }
  end

  before do
    Rake::Task['club_transfers:fetch_data'].reenable
    allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return(tm_data)
  end

  # Captures the CSV that the task would upload to S3.
  def run_and_capture
    captured = nil
    allow(ClubTransfersTasks).to receive(:upload_to_s3) do |local_path, _key|
      captured = File.read(local_path)
      'https://example.com/uploaded.csv'
    end
    Rake::Task['club_transfers:fetch_data'].invoke(player.id.to_s, player.id.to_s)
    CSV.parse(captured, headers: true)
  end

  context 'when the player changed to a different club' do
    subject(:rows) { run_and_capture }

    it { expect(rows.size).to eq(1) }
    it { expect(rows.first['player_id']).to eq(player.id.to_s) }
    it { expect(rows.first['new_club_name']).to eq(new_club.name) }
  end

  it 'skips the player when the transfer is already recorded' do
    create(:club_transfer, player: player, new_club: new_club, new_club_name: new_club.name)

    expect(run_and_capture.size).to eq(0)
  end
end
# rubocop:enable RSpec/DescribeClass
