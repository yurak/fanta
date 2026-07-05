# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/club_transfers')
Rake::Task.define_task(:environment)

RSpec.describe 'club_transfers:import_history rake task' do
  let!(:player) { create(:player, tm_id: 400_489) }

  before do
    Rake::Task['club_transfers:import_history'].reenable
    allow(ClubTransfers::HistoryImporter).to receive(:call).and_return(2)
    allow(ClubTransfers::RequestBuilder).to receive(:call).and_return(nil)
  end

  it 'imports history for players in the id range' do
    Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, player.id.to_s)

    expect(ClubTransfers::HistoryImporter).to have_received(:call).with(player)
  end

  it 'builds requests after importing' do
    Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, player.id.to_s)

    expect(ClubTransfers::RequestBuilder).to have_received(:call).with(player)
  end

  it 'skips players without a tm_id' do
    other = create(:player, tm_id: nil)
    Rake::Task['club_transfers:import_history'].invoke(other.id.to_s, other.id.to_s)

    expect(ClubTransfers::HistoryImporter).not_to have_received(:call)
  end
end
# rubocop:enable RSpec/DescribeClass
