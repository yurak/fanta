# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'
require 'csv'
require 'tempfile'

Rake.application.rake_require('tasks/club_transfers')
Rake::Task.define_task(:environment)

RSpec.describe 'club_transfers:create_and_apply rake task' do
  let(:tournament) { create(:tournament) }
  let(:old_club) { create(:club, tournament: tournament) }
  let(:new_club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: old_club) }
  let(:headers) do
    %w[player_id player_name current_club_id current_club_name tm_club_id new_club_id new_club_name club_joined_on
       contract_until loan]
  end
  let(:row) do
    [player.id, player.name, old_club.id, old_club.name, '1047', new_club.id, new_club.name, '2024-07-30', nil, 'false']
  end

  before { Rake::Task['club_transfers:create_and_apply'].reenable }

  def csv_tempfile(rows)
    file = Tempfile.new(['caa', '.csv'])
    CSV.open(file.path, 'w') do |csv|
      csv << headers
      rows.each { |r| csv << r }
    end
    file
  end

  def run(rows, dry: false)
    allow(ClubTransfersTasks).to receive(:download_from_s3).and_return(csv_tempfile(rows))
    args = ['https://example.com/data.csv']
    args << 'dry' if dry
    Rake::Task['club_transfers:create_and_apply'].invoke(*args)
  end

  it 'applies an in-DB club change via ClubChanger' do
    allow(Players::ClubChanger).to receive(:call).and_return(true)
    run([row])
    expect(Players::ClubChanger).to have_received(:call).with(hash_including(player: player, new_club_id: new_club.id))
  end

  it 'does not apply anything in dry mode' do
    allow(Players::ClubChanger).to receive(:call)
    run([row], dry: true)
    expect(Players::ClubChanger).not_to have_received(:call)
  end

  it 'skips a row already recorded as a ClubTransfer' do
    create(:club_transfer, player: player, new_club: new_club, new_club_name: new_club.name, start_date: '2024-07-30')
    allow(Players::ClubChanger).to receive(:call)
    run([row])
    expect(Players::ClubChanger).not_to have_received(:call)
  end
end
# rubocop:enable RSpec/DescribeClass
