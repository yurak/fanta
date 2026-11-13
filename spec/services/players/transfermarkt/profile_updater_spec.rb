require 'rails_helper'

RSpec.describe Players::Transfermarkt::ProfileUpdater do
  let(:player) do
    create(:player, tm_id: 400_489, tm_price: 13_000_000, number: 7, height: 180, nationality: 'de',
                    birth_date: '01/01/1999')
  end

  def stub_parser(result)
    allow(Players::Transfermarkt::ApiParser).to receive(:call)
      .with(player.tm_id, position_skip: true).and_return(result)
  end

  describe '#call' do
    it 'writes the new value' do
      stub_parser({ tm_price: 18_000_000 })

      expect { described_class.call(player) }.to change { player.reload.tm_price.to_i }.to(18_000_000)
    end

    it 'reports what moved' do
      stub_parser({ tm_price: 18_000_000, number: 9 })

      expect(described_class.call(player)).to eq(tm_price: [13_000_000, 18_000_000], number: [7, 9])
    end

    it 'reports nothing when the data matches' do
      stub_parser({ tm_price: 13_000_000, number: 7, height: 180, nationality: 'de' })

      expect(described_class.call(player)).to eq({})
    end

    # TM leaves the value out for retired players and most lower leagues, and reports it as a blank
    # rather than as a drop to zero.
    it 'keeps the stored value when the parser reports none' do
      stub_parser({ tm_price: 0, number: 0, height: 0, nationality: '' })

      expect(described_class.call(player)).to eq({})
    end

    it 'keeps the stored data when the parser fails' do
      stub_parser(false)

      expect { described_class.call(player) }.not_to(change { player.reload.tm_price.to_i })
    end

    # birth_date is a string column in TM's own %d/%m/%Y; it must be stored verbatim.
    it 'stores the birth date as the parser gave it' do
      stub_parser({ birth_date: '04/03/2000' })

      expect { described_class.call(player) }.to change { player.reload.birth_date }.to('04/03/2000')
    end

    it 'ignores a blank birth date' do
      stub_parser({ birth_date: nil })

      expect(described_class.call(player)).to eq({})
    end

    it 'touches only the fields it was asked for' do
      stub_parser({ tm_price: 18_000_000, number: 9 })

      expect { described_class.call(player, only: [:tm_price]) }.not_to(change { player.reload.number })
    end

    it 'does nothing without a tm_id' do
      expect(described_class.call(create(:player, tm_id: nil))).to eq({})
    end
  end
end
