require 'rails_helper'

RSpec.describe DivisionLevelSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:division), season_id: create(:season).id, tournament_id: create(:tournament).id)

      expect(serializer.serializable_hash.keys).to match_array(%i[id level leagues])
    end
  end

  describe '#leagues' do
    it 'returns only leagues from provided season and tournament' do
      data = prepare_leagues_data

      expect(data[:serializer].leagues.map(&:object)).to match_array(data[:matching_leagues])
    end

    it 'returns league base serializers' do
      data = prepare_leagues_data

      expect(data[:serializer].leagues.first).to be_a(LeagueBaseSerializer)
    end
  end

  def prepare_leagues_data
    season = create(:season)
    another_season = create(:season)
    tournament = create(:tournament)
    another_tournament = create(:tournament)
    division_level = create(:division, level: 'A', number: 1)
    same_level_other_division = create(:division, level: 'A', number: 2)
    different_level_division = create(:division, level: 'B', number: 1)

    matching_league = create(:league, season: season, tournament: tournament, division: division_level)
    same_level_matching_league = create(:league, season: season, tournament: tournament, division: same_level_other_division)
    create(:league, season: another_season, tournament: tournament, division: division_level)
    create(:league, season: season, tournament: another_tournament, division: division_level)
    create(:league, season: season, tournament: tournament, division: different_level_division)

    serializer = described_class.new(division_level, season_id: season.id, tournament_id: tournament.id)

    { serializer: serializer, matching_leagues: [matching_league, same_level_matching_league] }
  end
end
