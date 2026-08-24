require 'rails_helper'

RSpec.describe WeeklyTeams::AuctionAvgBuilder do
  subject(:result) { described_class.call(tournament.id, season.id) }

  let(:tournament) { Tournament.first }
  let!(:season)    { Season.last }

  def league_with_auction
    league  = create(:league, tournament: tournament, season: season, division: create(:division))
    auction = create(:auction, league: league, number: 1)
    [league, auction]
  end

  def buy(league_auction, player, price, status: :incoming)
    league, auction = league_auction
    create(:transfer, auction: auction, league: league, player: player,
                      team: create(:team, league: league), status: status, price: price)
  end

  def por_entry
    _mod, team = result.first
    team.find { |row| row[:slot].position == 'Por' }[:entry]
  end

  context 'when the tournament has no leagues this season' do
    it { is_expected.to eq([]) }
  end

  context 'when a player is bought across leagues' do
    let(:player) { create(:player, :with_pos_por) }

    before do
      buy(league_with_auction, player, 6)
      buy(league_with_auction, player, 8)
    end

    it 'returns one pair per team module' do
      expect(result.size).to eq(TeamModule.count)
    end

    it 'stores the average purchase price as total' do
      expect(por_entry[:total]).to eq(7.0)
    end

    it 'stores the highest purchase price as max_price' do
      expect(por_entry[:max_price]).to eq(8)
    end

    it 'stores the number of leagues the player was bought in' do
      expect(por_entry[:appearances]).to eq(2)
    end
  end

  context 'when a player is bought in fewer than half the leagues' do
    let(:rare)   { create(:player, :with_pos_por) }
    let(:common) { create(:player, :with_pos_por) }

    before do
      leagues = Array.new(3) { league_with_auction }
      buy(leagues[0], rare, 90)                 # 1 of 3 leagues — below the half threshold
      leagues.each { |la| buy(la, common, 5) }  # 3 of 3 leagues
    end

    it 'excludes the rarely-bought player even though he is pricier' do
      expect(por_entry[:player]).to eq(common)
    end
  end

  context 'when there are non-primary or non-incoming transfers' do
    let(:player) { create(:player, :with_pos_por) }

    before do
      league, auction = league_with_auction
      create(:transfer, auction: auction, league: league, player: player,
                        team: create(:team, league: league), status: :incoming, price: 5)
      # a later-round auction and an outgoing transfer must be ignored
      secondary = create(:auction, league: league, number: 2)
      create(:transfer, auction: secondary, league: league, player: player,
                        team: create(:team, league: league), status: :incoming, price: 99)
      create(:transfer, auction: auction, league: league, player: player,
                        team: create(:team, league: league), status: :outgoing, price: 99)
    end

    it 'averages only primary-auction incoming purchases' do
      expect(por_entry[:total]).to eq(5.0)
    end
  end

  context 'when a league has no division' do
    let(:player) { create(:player, :with_pos_por) }

    before do
      buy(league_with_auction, player, 5)
      no_div_league  = create(:league, tournament: tournament, season: season, division: nil)
      no_div_auction = create(:auction, league: no_div_league, number: 1)
      create(:transfer, auction: no_div_auction, league: no_div_league, player: player,
                        team: create(:team, league: no_div_league), status: :incoming, price: 99)
    end

    it 'ignores prices from leagues without a division' do
      expect(por_entry[:total]).to eq(5.0)
    end
  end
end
