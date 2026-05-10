# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/national_matches')
Rake::Task.define_task(:environment)

RSpec.describe 'national_matches rake tasks' do
  def reenable(task_name)
    Rake::Task[task_name].reenable
  end

  describe 'national_matches:generate_by_url' do
    let(:file_url) { 'https://example.com/matches.csv' }
    let(:tournament) { create(:tournament, code: 'world_cup') }
    let(:season) { Season.last || create(:season) }
    let(:host_team) { create(:national_team, name: 'Mexico', tournament: tournament) }
    let(:guest_team) { create(:national_team, name: 'South Africa', tournament: tournament) }
    let(:round) { create(:tournament_round, number: 1, tournament: tournament, season: season) }
    let(:csv_content) do
      rows = [
        %w[fotmob_id home_club away_club date score page_url round_number],
        ['4667751', host_team.name, guest_team.name, '2026-06-11T19:00:00Z', '',
         '/matches/south-africa-vs-mexico/1einvt#4667751', round.number.to_s]
      ]
      rows.map { |r| r.join(',') }.join("\n")
    end

    before do
      round
      uri_double = instance_double(URI::HTTPS, open: StringIO.new(csv_content))
      allow(URI).to receive(:parse).with(file_url).and_return(uri_double)
      reenable('national_matches:generate_by_url')
    end

    it 'creates a NationalMatch record' do
      expect do
        Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      end.to change(NationalMatch, :count).by(1)
    end

    it 'assigns host team correctly' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.host_team).to eq(host_team)
    end

    it 'assigns guest team correctly' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.guest_team).to eq(guest_team)
    end

    it 'assigns tournament_round correctly' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.tournament_round).to eq(round)
    end

    it 'parses date from the CSV' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.date).to eq('JUN 11, 2026')
    end

    it 'parses time from the CSV' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.time).to eq('19:00')
    end

    it 'assigns source_match_id' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.source_match_id).to eq('4667751')
    end

    it 'assigns page_url' do
      Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
      expect(NationalMatch.last.page_url).to eq('/matches/south-africa-vs-mexico/1einvt#4667751')
    end

    context 'when a team is not in the tournament (e.g. Undefined)' do
      before do
        other_team = create(:national_team, name: 'Undefined')
        csv = [
          %w[fotmob_id home_club away_club date score page_url round_number].join(','),
          ['4667800', host_team.name, other_team.name, '2026-06-12T15:00:00Z', '',
           '/matches/undefined/1#4667800', round.number.to_s].join(',')
        ].join("\n")
        uri_double = instance_double(URI::HTTPS, open: StringIO.new(csv))
        allow(URI).to receive(:parse).with(file_url).and_return(uri_double)
      end

      it 'creates the match using the team from another tournament' do
        expect do
          Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
        end.to change(NationalMatch, :count).by(1)
      end

      it 'assigns the cross-tournament team as guest' do
        Rake::Task['national_matches:generate_by_url'].invoke(file_url, tournament.code)
        expect(NationalMatch.last.guest_team).to eq(NationalTeam.find_by(name: 'Undefined'))
      end
    end

    context 'when tournament code does not exist' do
      before { reenable('national_matches:generate_by_url') }

      it 'does not create any matches' do
        expect do
          Rake::Task['national_matches:generate_by_url'].invoke(file_url, 'nonexistent')
        end.not_to change(NationalMatch, :count)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
