RSpec.describe Fanta::Release do
  describe '.version' do
    it 'reads the release number out of the VERSION file' do
      # Pinned to the shape, not the number — asserting the number would make every release
      # break this example, which is the drift the file itself is meant to survive.
      expect(described_class.version).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '.revision' do
    it 'is absent outside a deployed release, where Capistrano writes no REVISION' do
      expect(described_class.revision).to be_nil
    end
  end

  describe '.label' do
    it 'pairs the release number with a short SHA' do
      allow(described_class).to receive_messages(version: '5.5.2', revision: 'a67b9f0abc1234')

      expect(described_class.label).to eq('5.5.2 (a67b9f0)')
    end

    it 'falls back to the release number alone when there is no revision' do
      allow(described_class).to receive_messages(version: '5.5.2', revision: nil)

      expect(described_class.label).to eq('5.5.2')
    end

    it 'falls back to the revision alone when there is no VERSION file' do
      allow(described_class).to receive_messages(version: nil, revision: 'a67b9f0abc1234')

      expect(described_class.label).to eq('(a67b9f0)')
    end

    it 'is nil when neither is known, so the view can skip the line' do
      allow(described_class).to receive_messages(version: nil, revision: nil)

      expect(described_class.label).to be_nil
    end
  end
end
