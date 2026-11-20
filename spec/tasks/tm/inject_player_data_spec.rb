require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/tm/inject_player_data')
Rake::Task.define_task(:environment)

RSpec.describe 'tm:inject_player_data rake task' do # rubocop:disable RSpec/DescribeClass
  let!(:player) { create(:player, tm_id: 400_489, tm_price: 6_000_000) }

  def run
    Rake::Task['tm:inject_player_data'].reenable
    Rake::Task['tm:inject_player_data'].invoke(player.id.to_s, player.id.to_s)
  end

  before do
    stub_const('ENV', ENV.to_h.merge('TM_SLEEP' => '0'))
    allow(Players::Transfermarkt::CacheProbe).to receive(:fresh?).and_return(true)
  end

  it 'prints a price at a readable scale' do
    allow(Players::Transfermarkt::ProfileUpdater).to receive(:call)
      .and_return({ tm_price: [6_000_000, 18_500_000] })

    expect { run }.to output(/tm_price 6_000_000 -> 18_500_000/).to_stdout
  end

  it 'leaves a shirt number alone' do
    allow(Players::Transfermarkt::ProfileUpdater).to receive(:call).and_return({ number: [7, 9] })

    expect { run }.to output(/number 7 -> 9/).to_stdout
  end

  it 'leaves a birth date alone' do
    allow(Players::Transfermarkt::ProfileUpdater).to receive(:call)
      .and_return({ birth_date: ['01/01/1999', '04/03/2000'] })

    expect { run }.to output(%r{birth_date 01/01/1999 -> 04/03/2000}).to_stdout
  end

  it 'reports nothing extra when the data matches' do
    allow(Players::Transfermarkt::ProfileUpdater).to receive(:call).and_return({})

    expect { run }.to output(%r{#{player.id} / #{player.name} \[cache\]\n}).to_stdout
  end
end
