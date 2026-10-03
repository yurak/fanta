require 'rails_helper'

RSpec.describe PlayerSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  describe 'the wishlist state' do
    subject(:hash) { described_class.new(player, current_user: viewer).serializable_hash }

    let!(:season) { Season.last || create(:season) }
    let(:viewer) { create(:user) }
    let(:tournament) { create(:tournament) }
    let(:player) { create(:player, club: create(:club, tournament: tournament)) }

    context 'with a player nobody wished for' do
      it { expect(hash[:wishlistable]).to be(true) }
      it { expect(hash[:wishlisted]).to be(false) }
      it { expect(hash[:wishlist_id]).to be_nil }
    end

    context 'with a player on the viewer list' do
      before { Wishlists::PlayerUpdater.call(user: viewer, player: player, wanted: true) }

      it { expect(hash[:wishlisted]).to be(true) }

      it 'points at the list he is on' do
        expect(hash[:wishlist_id]).to eq(viewer.wishlists.find_by(season: season).id)
      end
    end

    # Someone else wishing for him says nothing about this viewer.
    context 'with a player on a stranger list' do
      before { Wishlists::PlayerUpdater.call(user: create(:user), player: player, wanted: true) }

      it { expect(hash[:wishlisted]).to be(false) }
    end

    context 'with a fanta player' do
      let(:tournament) { create(:fanta_tournament) }

      it { expect(hash[:wishlistable]).to be(false) }
      it { expect(hash[:wishlisted]).to be(false) }
    end

    # A guest is shown no heart at all rather than one that refuses on click.
    context 'without a signed-in viewer' do
      let(:viewer) { nil }

      it { expect(hash[:wishlistable]).to be(false) }
      it { expect(hash[:wishlisted]).to be(false) }
    end
  end

  def expected_keys
    %i[
      id appearances appearances_max avatar_path average_base_score average_price average_total_score club
      first_name league_price league_team_logo name newbie position_classic_arr position_ital_arr teams_count
      teams_count_max age birth_date country height leagues national_team number profile_avatar_path
      stats_price team_ids tm_price tm_url club_transfers nationality profile_kit_path season_score teams
      wishlistable wishlisted wishlist_id
    ]
  end
end
