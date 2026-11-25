RSpec.describe ApplicationHelper do
  describe '#position_number(index)' do
    context 'with prize index' do
      it 'returns medal emoji' do
        expect(helper.position_number(1)).to eq('🥇')
      end
    end

    context 'with lower index' do
      let(:index) { 5 }

      it 'returns index' do
        expect(helper.position_number(index)).to eq(index)
      end
    end
  end

  describe '#position_manager_number(index)' do
    context 'with prize index' do
      it 'returns medal emoji' do
        expect(helper.position_manager_number(1)).to eq('🥇 #1')
      end
    end

    context 'with lower index' do
      let(:index) { 5 }

      it 'returns index' do
        expect(helper.position_manager_number(index)).to eq('#5')
      end
    end
  end

  describe '#ordinalize_number(number)' do
    context 'without number' do
      it 'returns -' do
        expect(helper.ordinalize_number(nil)).to eq('-')
      end
    end

    context 'with number and en locale' do
      it 'returns ordinalize number' do
        expect(helper.ordinalize_number(2)).to eq('2nd')
      end
    end

    context 'with number and ua locale' do
      around do |example|
        I18n.with_locale(:ua) do
          example.run
        end
      end

      it 'returns ordinalize number' do
        expect(helper.ordinalize_number(2)).to eq(2)
      end
    end
  end

  describe '#any_wishlist?' do
    let(:user) { create(:user) }
    let!(:season) { Season.last || create(:season) }

    context 'with a guest' do
      before { allow(helper).to receive(:user_signed_in?).and_return(false) }

      it { expect(helper.any_wishlist?).to be(false) }
    end

    context 'with a manager who has never pressed the heart' do
      before do
        allow(helper).to receive_messages(user_signed_in?: true, current_user: user)
      end

      it { expect(helper.any_wishlist?).to be(false) }
    end

    context 'with a manager who keeps a list' do
      before do
        create(:wishlist, user: user, season: season)
        allow(helper).to receive_messages(user_signed_in?: true, current_user: user)
      end

      it { expect(helper.any_wishlist?).to be(true) }
    end

    # Last season's list says nothing about this one, and the page only ever shows the current one.
    context 'with a list from a past season only' do
      before do
        create(:wishlist, user: user, season: season)
        create(:season, start_year: 2030, end_year: 2031) # newer, so `season` is no longer the current one
        allow(helper).to receive_messages(user_signed_in?: true, current_user: user)
      end

      it { expect(helper.any_wishlist?).to be(false) }
    end
  end

  describe '#external_url(value)' do
    it 'passes an http URL through' do
      expect(helper.external_url('http://example.com/a?b=c')).to eq('http://example.com/a?b=c')
    end

    it 'passes an https URL through' do
      expect(helper.external_url('https://www.transfermarkt.com/club/startseite/verein/27')).to \
        eq('https://www.transfermarkt.com/club/startseite/verein/27')
    end

    # The point of the helper: these are all valid href values, and all of them run or load
    # something other than a page when clicked.
    it 'refuses a javascript: URL' do
      expect(helper.external_url('javascript:alert(1)')).to be_nil
    end

    it 'refuses a data: URL' do
      expect(helper.external_url('data:text/html,<script>alert(1)</script>')).to be_nil
    end

    it 'refuses a relative path, which an href would resolve against our own host' do
      expect(helper.external_url('/manage/clubs')).to be_nil
    end

    it 'refuses a string URI cannot parse' do
      expect(helper.external_url('http://a b c')).to be_nil
    end

    it 'refuses nil' do
      expect(helper.external_url(nil)).to be_nil
    end

    it 'refuses an empty string' do
      expect(helper.external_url('')).to be_nil
    end
  end
end
