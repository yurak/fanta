RSpec.describe Players::Transfermarkt::NameNormalizer do
  describe '.normalize_name' do
    it 'folds the Romanian comma-below letters I18n.transliterate turns into "?"' do
      expect(described_class.normalize_name('Olimpiu Moruțan')).to eq('Olimpiu Morutan')
    end

    it 'folds the comma-below s as well' do
      expect(described_class.normalize_name('Nicușor Bancu')).to eq('Nicusor Bancu')
    end

    it 'keeps stripping ordinary accents' do
      expect(described_class.normalize_name('Darwin Núñez')).to eq('Darwin Nunez')
    end

    it 'still handles letters that have no decomposition' do
      expect(described_class.normalize_name('Đorđe Petrović')).to eq('Dorde Petrovic')
    end

    it 'leaves an ASCII name alone' do
      expect(described_class.normalize_name('Harry Kane')).to eq('Harry Kane')
    end

    it 'copes with nil' do
      expect(described_class.normalize_name(nil)).to eq('')
    end
  end
end
