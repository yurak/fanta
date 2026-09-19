require 'rails_helper'

RSpec.describe Standings::Updater do
  subject(:update) { described_class.call(tournament, season: season) }

  let(:season) { Season.last || create(:season) }
  let(:tournament) { create(:tournament, source_id: 441) }
  let!(:club) { create(:club, tournament: tournament, fotmob_id: 9728) }
  let(:rows) do
    [{ position: 1, fotmob_team_id: 9728, team_name: 'Shakhtar Donetsk', played: 6, wins: 5, draws: 0,
       losses: 1, goals_for: 12, goals_against: 4, points: 15, zone_color: '#FFD908' },
     { position: 2, fotmob_team_id: 8688, team_name: 'Dynamo Kyiv', played: 6, wins: 4, draws: 1,
       losses: 1, goals_for: 9, goals_against: 5, points: 13, zone_color: '' }]
  end

  before { allow(Standings::FotmobParser).to receive(:call).and_return(rows) }

  it 'writes a row per team' do
    expect { update }.to change { Standing.where(tournament: tournament, season: season).count }.from(0).to(2)
  end

  it 'links the club by its FotMob id, not by name' do
    update

    expect(Standing.find_by(tournament: tournament, position: 1).club).to eq(club)
  end

  it 'keeps the source name when we do not carry the club' do
    update

    standing = Standing.find_by(tournament: tournament, position: 2)
    expect([standing.club, standing.display_name]).to eq([nil, 'Dynamo Kyiv'])
  end

  it 'returns the number of rows written' do
    expect(update).to eq(2)
  end

  context 'when the table is refreshed again' do
    before { described_class.call(tournament, season: season) }

    it 'updates in place instead of duplicating' do
      expect { update }.not_to(change { Standing.where(tournament: tournament, season: season).count })
    end

    it 'moves a team that changed position' do
      allow(Standings::FotmobParser).to receive(:call)
        .and_return([rows.second.merge(position: 1), rows.first.merge(position: 2)])

      update

      expect(Standing.find_by(tournament: tournament, position: 1).team_name).to eq('Dynamo Kyiv')
    end
  end

  context 'when the division shrinks' do
    before do
      described_class.call(tournament, season: season)
      allow(Standings::FotmobParser).to receive(:call).and_return([rows.first])
    end

    it 'drops the rows that fell off the bottom' do
      expect { update }.to change { Standing.where(tournament: tournament, season: season).count }.from(2).to(1)
    end
  end

  # A failed scrape must not read as "the table is empty" — a stale table is still a correct one.
  context 'when FotMob gives nothing' do
    before do
      described_class.call(tournament, season: season)
      allow(Standings::FotmobParser).to receive(:call).and_return([])
    end

    it 'keeps what we already had' do
      expect { update }.not_to(change { Standing.where(tournament: tournament, season: season).count })
    end

    it { is_expected.to eq(0) }
  end

  # FotMob fills a national tournament's table with draw placeholders ("1A", "2A") that carry
  # real-looking ids, and there are no clubs to link them to.
  context 'without clubs in the tournament' do
    let(:tournament) { create(:tournament, source_id: 50) }
    let!(:club) { nil }

    it { is_expected.to eq(0) }

    it 'writes nothing' do
      update

      expect(Standing.where(tournament: tournament).count).to eq(0)
    end

    it 'does not even fetch' do
      update

      expect(Standings::FotmobParser).not_to have_received(:call)
    end
  end
end
