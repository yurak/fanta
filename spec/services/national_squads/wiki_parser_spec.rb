RSpec.describe NationalSquads::WikiParser do
  subject(:players) { described_class.call(wikitext) }

  def player_template(name, pos: 'MF', club: 'Bayern Munich', born: '{{Birth date and age|df=y|1999|4|20}}', tag: 'nat fs g player')
    "{{#{tag}|no=|pos=#{pos}|name=[[#{name}]]|age=#{born}|club=[[FC #{club}|#{club}]]|clubnat=GER}}"
  end

  context 'with a plain squad table' do
    let(:wikitext) do
      <<~WIKI
        ===Current squad===
        {{nat fs g start}}
        #{player_template('Manuel Neuer', pos: 'GK')}
        #{player_template('Joshua Kimmich')}
        {{nat fs g end}}
      WIKI
    end

    it 'reads both players' do
      expect(players.pluck(:name)).to eq(['Manuel Neuer', 'Joshua Kimmich'])
    end

    it 'reads the position' do
      expect(players.first[:position]).to eq('GK')
    end

    it 'reads the club through the piped link' do
      expect(players.first[:club]).to eq('Bayern Munich')
    end

    it 'reads the birth date' do
      expect(players.first[:birth_date]).to eq('1999-04-20')
    end
  end

  # Articles mix `{{nat fs g player}}` and `{{Nat fs g player}}`. A case-sensitive search dropped
  # Dembélé from France's squad and it read as a withdrawal that never happened.
  context 'with a template written with a capital letter' do
    let(:wikitext) do
      <<~WIKI
        ===Current squad===
        {{nat fs g start}}
        #{player_template('Ousmane Dembele').sub('{{nat', '{{Nat')}
        {{nat fs g end}}
      WIKI
    end

    it 'still reads the player' do
      expect(players.pluck(:name)).to eq(['Ousmane Dembele'])
    end
  end

  # The table below the squad lists everyone called up over the last year. Those players were NOT
  # called up this time — reading them made Ireland look like a 66-man squad.
  context 'with a recent call-ups table underneath' do
    let(:wikitext) do
      <<~WIKI
        ===Current squad===
        {{nat fs g start}}
        #{player_template('Called Up')}
        {{nat fs g end}}
        ===Recent call-ups===
        {{nat fs r start}}
        #{player_template('Left Behind', tag: 'nat fs r player')}
        {{nat fs r end}}
      WIKI
    end

    it 'takes only the squad' do
      expect(players.pluck(:name)).to eq(['Called Up'])
    end
  end

  # `{{nat fs break}}` splits the table into columns. Treating it as the end loses most of the squad.
  context 'with a column break inside the table' do
    let(:wikitext) do
      <<~WIKI
        ===Current squad===
        {{nat fs g start}}
        #{player_template('First Column')}
        {{nat fs break}}
        #{player_template('Second Column')}
        {{nat fs g end}}
      WIKI
    end

    it 'reads both sides of the break' do
      expect(players.pluck(:name)).to eq(['First Column', 'Second Column'])
    end
  end

  context 'with footnotes and references on the name' do
    let(:wikitext) do
      <<~WIKI
        ===Current squad===
        {{nat fs g start}}
        {{nat fs g player|no=|pos=DF|name=[[Jonathan Tah]]{{efn|name=First}}<ref name="squad"/>|age={{bda|1996|2|11|df=y}}|club=[[FC Bayern Munich|Bayern Munich]]}}
        {{nat fs g end}}
      WIKI
    end

    it 'strips them from the name' do
      expect(players.first[:name]).to eq('Jonathan Tah')
    end

    it 'reads a birth date written with the bda shorthand' do
      expect(players.first[:birth_date]).to eq('1996-02-11')
    end
  end

  context 'without a squad section' do
    let(:wikitext) { '==History==\nThe team was founded in 1900.' }

    it { expect(players).to eq([]) }
  end

  context 'with nothing at all' do
    let(:wikitext) { nil }

    it { expect(players).to eq([]) }
  end
end
