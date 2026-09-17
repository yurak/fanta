require 'rails_helper'

RSpec.describe 'standings/_table' do
  subject(:html) { render partial: 'standings/table', locals: locals }

  let(:tournament) { create(:tournament) }
  let(:club) { create(:club, tournament: tournament, name: 'Polissya', code: 'POL') }
  let(:standing) do
    create(:standing, tournament: tournament, club: club, team_name: 'Polissya Zhytomyr',
                      position: 1, played: 6, wins: 5, draws: 0, losses: 1,
                      goals_for: 14, goals_against: 5, points: 15)
  end
  let(:locals) { { standings: [standing] } }

  it 'shows the club name we carry' do
    expect(html).to match(%r{standings-club-name">\s*Polissya\s*</span>})
  end

  it 'does not fall back to the source spelling' do
    expect(html).not_to include('Polissya Zhytomyr')
  end

  it 'shows the goals column' do
    expect(html).to include('14-5')
  end

  context 'with compact: true' do
    let(:locals) { { standings: [standing], compact: true } }

    # The tour stats column is far narrower than the lineup tab; a full club name pushes the table
    # past its parent.
    it 'shows the club code instead of the name' do
      expect(html).to match(%r{standings-club-name">\s*POL\s*</span>})
    end

    it 'does not spell the club out' do
      expect(html).not_to include('Polissya')
    end

    it 'drops the goals column' do
      expect(html).not_to include('14-5')
    end
  end

  context 'without a club of ours' do
    let(:standing) { create(:standing, tournament: tournament, club: nil, team_name: 'Kudrivka', position: 1) }
    let(:locals) { { standings: [standing], compact: true } }

    it 'falls back to the source name' do
      expect(html).to include('Kudrivka')
    end
  end

  # Only the lineup page passes opponents: the tour stats column lists the round's fixtures right
  # above the table, so the same information twice would be noise.
  context 'with opponents' do
    let(:rival) { create(:club, tournament: tournament, name: 'Epicentr') }
    let(:locals) { { standings: [standing], opponents: { club.id => rival } } }

    it 'shows the opponent crest' do
      expect(html).to include(rival.logo_path)
    end

    it 'names the opponent for hover' do
      expect(html).to include('title="Epicentr"')
    end

    it 'puts the column last' do
      expect(html).to match(/standings-points">.*?standings-opponent/m)
    end

    # The script that lights up both sides of a fixture pairs the rows through these.
    it 'carries the club and its opponent as data attributes' do
      expect(html).to include(%(data-club-id="#{club.id}" data-opponent-id="#{rival.id}"))
    end

    context 'when the club does not play this round' do
      let(:locals) { { standings: [standing], opponents: {} } }

      it 'marks the row instead of leaving a hole' do
        expect(html).to include('standings-opponent-none')
      end
    end
  end

  context 'without opponents' do
    it 'does not add the column' do
      expect(html).not_to include('standings-opponent')
    end

    it 'leaves the rows unpaired' do
      expect(html).not_to include('data-club-id')
    end
  end
end
