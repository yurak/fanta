RSpec.describe NationalSquads::Comparer do
  subject(:result) { described_class.call(team, ours, theirs) }

  let(:team) { 'Germany' }

  def wiki_player(name)
    { name: name, position: 'MF', club: 'Bayern Munich', birth_date: '1999-04-20' }
  end

  context 'with the same squad on both sides' do
    let(:ours) { ['Joshua Kimmich', 'Jamal Musiala'] }
    let(:theirs) { [wiki_player('Joshua Kimmich'), wiki_player('Jamal Musiala')] }

    it { expect(result).not_to be_changed }
    it { expect(result.gone).to be_empty }
    it { expect(result.arrived).to be_empty }
  end

  context 'with a player replaced' do
    let(:ours) { ['Joshua Kimmich', 'Jamal Musiala'] }
    let(:theirs) { [wiki_player('Joshua Kimmich'), wiki_player('Florian Wirtz')] }

    it { expect(result).to be_changed }
    it { expect(result.gone).to eq(['Jamal Musiala']) }
    it { expect(result.arrived.pluck(:name)).to eq(['Florian Wirtz']) }
  end

  # Matching on "any shared word" without pairing one-to-one lets a single name of ours answer for two
  # of theirs, and the arrival then hides behind a head count that looks unchanged.
  context 'when one of our names shares a word with two of theirs' do
    let(:ours) { ['Ivan Petrov'] }
    let(:theirs) { [wiki_player('Ivan Petrov'), wiki_player('Ivan Kovalenko')] }

    it 'still reports the second one as an arrival' do
      expect(result.arrived.pluck(:name)).to eq(['Ivan Kovalenko'])
    end

    it 'pairs the exact name rather than the first it meets' do
      expect(result.gone).to be_empty
    end
  end

  # Known limit, worth knowing before trusting a quiet run: two leftovers that share a given name are
  # paired to each other, so a swap between two players called Ivan reads as no change. Nothing in the
  # squads we carry has hit it, and the alternative — demanding a surname match — would report every
  # transliteration as a change.
  context 'with a swap between two players sharing a given name' do
    let(:ours) { ['Ivan Sidorov'] }
    let(:theirs) { [wiki_player('Ivan Kovalenko')] }

    it 'does not notice' do
      expect(result).not_to be_changed
    end
  end

  context 'with the same name spelled differently' do
    let(:team) { 'Ukraine' }
    let(:ours) { ['Viktor Tsygankov', 'Oleksandr Drambaev'] }
    let(:theirs) { [wiki_player('Viktor Tsyhankov'), wiki_player('Oleksandr Drambayev')] }

    it 'treats transliterations as the same players' do
      expect(result).not_to be_changed
    end
  end

  context 'with Turkish dotless i' do
    let(:team) { 'Turkiye' }
    let(:ours) { ['Baris Alper Yilmaz'] }
    let(:theirs) { [wiki_player('Barış Yılmaz')] }

    it { expect(result).not_to be_changed }
  end

  # A nickname one source spells out in full and the other does not.
  context 'with a player listed under a nickname' do
    let(:team) { 'Spain' }
    let(:ours) { ['Rodrigo Hernandez'] }
    let(:theirs) { [wiki_player('Rodri')] }

    it { expect(result).not_to be_changed }

    context 'when the same name belongs to another team' do
      let(:team) { 'Italy' }

      it 'does not borrow the alias' do
        expect(result).to be_changed
      end
    end
  end

  context 'with a player carried twice, once per match window' do
    let(:ours) { ['Finn Dahmen', 'Finn Dahmen', 'Joshua Kimmich'] }
    let(:theirs) { [wiki_player('Finn Dahmen'), wiki_player('Joshua Kimmich')] }

    it 'counts him once' do
      expect(result.ours_count).to eq(2)
    end

    it { expect(result).not_to be_changed }
  end

  context 'with nobody on their side' do
    let(:ours) { ['Joshua Kimmich'] }
    let(:theirs) { [] }

    it { expect(result.gone).to eq(['Joshua Kimmich']) }
  end
end
