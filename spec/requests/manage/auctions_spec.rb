RSpec.describe 'Manage::Auctions' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_auctions_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_auctions_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:initial_auction) { create(:auction, status: :initial) }
      let!(:sales_auction)   { create(:auction, status: :sales) }

      before { get manage_auctions_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'defaults to initial tab' do
        expect(controller.instance_variable_get(:@status)).to eq('initial')
      end

      it 'shows only initial auctions by default' do
        expect(controller.instance_variable_get(:@auctions)).to include(initial_auction)
      end

      it 'excludes non-initial auctions by default' do
        expect(controller.instance_variable_get(:@auctions)).not_to include(sales_auction)
      end

      it 'renders the tournament as an icon carrying its name' do
        initial_auction.league.tournament.update!(name: 'Zzz Marker Cup')
        get manage_auctions_path
        expect(response.body).to include('title="Zzz Marker Cup"')
      end
    end

    context 'when admin filters by status' do
      login_admin

      let!(:sales_auction)   { create(:auction, status: :sales) }
      let!(:initial_auction) { create(:auction, status: :initial) }

      before { get manage_auctions_path(status: 'sales') }

      it 'shows only auctions with selected status' do
        expect(controller.instance_variable_get(:@auctions)).to include(sales_auction)
      end

      it 'excludes auctions with other statuses' do
        expect(controller.instance_variable_get(:@auctions)).not_to include(initial_auction)
      end
    end

    context 'when admin provides invalid status' do
      login_admin

      before { get manage_auctions_path(status: 'invalid') }

      it 'defaults to initial' do
        expect(controller.instance_variable_get(:@status)).to eq('initial')
      end
    end

    context 'when filtering by league name query' do
      login_admin

      let!(:matching_auction)  { create(:auction, league: create(:league, name: 'Alpha League')) }
      let!(:excluded_auction)  { create(:auction, league: create(:league, name: 'Beta League')) }

      before { get manage_auctions_path(query: 'Alpha') }

      it 'includes matching auction' do
        expect(controller.instance_variable_get(:@auctions)).to include(matching_auction)
      end

      it 'excludes non-matching auction' do
        expect(controller.instance_variable_get(:@auctions)).not_to include(excluded_auction)
      end
    end

    context 'when filtering by tournament' do
      login_admin

      let(:tournament_a) { create(:tournament) }
      let(:tournament_b) { create(:tournament) }
      let!(:auction_a)   { create(:auction, league: create(:league, tournament: tournament_a)) }
      let!(:auction_b)   { create(:auction, league: create(:league, tournament: tournament_b)) }

      before { get manage_auctions_path(tournament_id: tournament_a.id) }

      it 'includes auction for selected tournament' do
        expect(controller.instance_variable_get(:@auctions)).to include(auction_a)
      end

      it 'excludes auction for other tournament' do
        expect(controller.instance_variable_get(:@auctions)).not_to include(auction_b)
      end
    end

    context 'when filtering by season' do
      login_admin

      let(:season_a) { create(:season) }
      let(:season_b) { create(:season) }
      let!(:auction_a) { create(:auction, league: create(:league, season: season_a)) }
      let!(:auction_b) { create(:auction, league: create(:league, season: season_b)) }

      before { get manage_auctions_path(season_id: season_a.id) }

      it 'includes auction for selected season' do
        expect(controller.instance_variable_get(:@auctions)).to include(auction_a)
      end

      it 'excludes auction for other season' do
        expect(controller.instance_variable_get(:@auctions)).not_to include(auction_b)
      end
    end

    context 'when ordering by deadline' do
      login_admin

      # Deadline column: last round's deadline, falling back to the auction's own deadline.
      let!(:late)     { create(:auction, deadline: Time.zone.parse('2026-08-10 12:00')) }
      let!(:early)    { create(:auction, deadline: Time.zone.parse('2026-08-01 12:00')) }
      let!(:middle)   { create(:auction, deadline: Time.zone.parse('2026-07-01 12:00')) }
      let!(:no_dates) { create(:auction, deadline: nil) }

      before do
        create(:auction_round, auction: middle, number: 1, deadline: Time.zone.parse('2026-08-03 12:00'))
        create(:auction_round, auction: middle, number: 2, deadline: Time.zone.parse('2026-08-05 12:00'))
        get manage_auctions_path
      end

      it 'lists the nearest deadline first, using the last round deadline' do
        expect(controller.instance_variable_get(:@auctions).to_a.first(3)).to eq([early, middle, late])
      end

      it 'puts auctions without any deadline last' do
        expect(controller.instance_variable_get(:@auctions).to_a.last).to eq(no_dates)
      end
    end

    context 'when deadline-less auctions have a base_date' do
      login_admin

      # January vs February: chronological order differs from alphabetical order.
      let!(:february) { create(:auction, deadline: nil, base_date: 'February, 2026') }
      let!(:january)  { create(:auction, deadline: nil, base_date: 'January, 2026') }
      let!(:undated)  { create(:auction, deadline: nil, base_date: nil) }

      before { get manage_auctions_path }

      it 'orders them chronologically by base_date, blanks last' do
        expect(controller.instance_variable_get(:@auctions).to_a).to eq([january, february, undated])
      end
    end

    context 'when viewing closed auctions' do
      login_admin

      let!(:stale)  { travel_to(Time.zone.parse('2026-07-01 12:00')) { create(:auction, status: :closed) } }
      let!(:recent) { travel_to(Time.zone.parse('2026-08-01 12:00')) { create(:auction, status: :closed) } }

      before { get manage_auctions_path(status: 'closed') }

      it 'lists the most recently edited auction first' do
        expect(controller.instance_variable_get(:@auctions).to_a.first(2)).to eq([recent, stale])
      end
    end

    context 'with pagination' do
      login_admin

      before do
        create_list(:auction, Manage::AuctionsController::PER_PAGE + 1)
        get manage_auctions_path
      end

      it 'paginates results' do
        expect(controller.instance_variable_get(:@auctions).count).to eq(Manage::AuctionsController::PER_PAGE)
      end
    end
  end
end
