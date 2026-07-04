# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'
require 'csv'
require 'tempfile'

Rake.application.rake_require('tasks/club_transfers')
Rake::Task.define_task(:environment)

RSpec.describe 'club_transfers:create_requests rake task' do
  let(:player) { create(:player) }
  let(:club) { create(:club) }
  let(:headers) do
    %w[player_id player_name current_club_id current_club_name tm_club_id new_club_id new_club_name club_joined_on
       contract_until loan]
  end

  before { Rake::Task['club_transfers:create_requests'].reenable }

  def csv_tempfile(rows)
    file = Tempfile.new(['ctr', '.csv'])
    CSV.open(file.path, 'w') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
    file
  end

  def run(rows)
    allow(ClubTransfersTasks).to receive(:download_from_s3).and_return(csv_tempfile(rows))
    Rake::Task['club_transfers:create_requests'].invoke('https://example.com/data.csv')
  end

  it 'creates a pending request from a CSV row' do
    row = [player.id, player.name, club.id, club.name, '1047', club.id, 'NewClub', '2024-07-30', '2028-06-30', 'false']

    expect { run([row]) }.to change(ClubTransferRequest.pending, :count).by(1)
  end

  it 'skips a row already recorded as a ClubTransfer' do
    create(:club_transfer, player: player, new_club: club, new_club_name: club.name, start_date: '2024-07-30')
    row = [player.id, player.name, nil, nil, '1047', club.id, club.name, '2024-07-30', nil, 'false']

    expect { run([row]) }.not_to change(ClubTransferRequest, :count)
  end

  it 'skips a row that already has a pending request' do
    create(:club_transfer_request, player: player, new_club: club, new_club_name: club.name, start_date: '2024-07-30')
    row = [player.id, player.name, nil, nil, '1047', club.id, club.name, '2024-07-30', nil, 'false']

    expect { run([row]) }.not_to change(ClubTransferRequest, :count)
  end
end
# rubocop:enable RSpec/DescribeClass
