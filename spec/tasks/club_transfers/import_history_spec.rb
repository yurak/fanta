require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/club_transfers')
Rake::Task.define_task(:environment)

RSpec.describe 'club_transfers:import_history rake task' do # rubocop:disable RSpec/DescribeClass
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

  # Transfermarkt hands out a short block on the first refusal and a long one if you keep knocking,
  # so the run must stop rather than walk the rest of the id range.
  context 'when Transfermarkt blocks the caller' do
    let!(:second_player) { create(:player, tm_id: 400_490) }

    before do
      allow(ClubTransfers::HistoryImporter).to receive(:call)
        .and_raise(Players::Transfermarkt::ApiError.new('RestClient::MethodNotAllowed (HTTP 405)', http_code: 405))
    end

    it 'stops after the first refusal' do
      Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, second_player.id.to_s)

      expect(ClubTransfers::HistoryImporter).to have_received(:call).once
    end

    it 'says why it stopped' do
      expect do
        Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, second_player.id.to_s)
      end.to output(/STOPPED: Transfermarkt refused the request/).to_stdout
    end
  end

  context 'when the host cannot be reached at all' do
    let!(:second_player) { create(:player, tm_id: 400_490) }

    before do
      allow(ClubTransfers::HistoryImporter).to receive(:call)
        .and_raise(Players::Transfermarkt::ApiUnavailableError.new('SocketError'))
    end

    it 'stops as well' do
      Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, second_player.id.to_s)

      expect(ClubTransfers::HistoryImporter).to have_received(:call).once
    end
  end

  context 'when a single player fails for another reason' do
    let!(:second_player) { create(:player, tm_id: 400_490) }

    before do
      allow(ClubTransfers::HistoryImporter).to receive(:call).and_raise(StandardError, 'boom')
    end

    it 'keeps going through the range' do
      Rake::Task['club_transfers:import_history'].invoke(player.id.to_s, second_player.id.to_s)

      expect(ClubTransfers::HistoryImporter).to have_received(:call).twice
    end
  end
end
