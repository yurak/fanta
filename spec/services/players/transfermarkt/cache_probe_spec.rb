require 'rails_helper'

RSpec.describe Players::Transfermarkt::CacheProbe do
  let(:tm_id) { 400_489 }
  let(:dir) { Rails.root.join('tmp/transfermarkt_cache') }
  let(:api_path) { dir.join("player_api_#{tm_id}.json") }

  before { FileUtils.mkdir_p(dir) }

  after { FileUtils.rm_f(api_path) }

  describe '.fresh?' do
    it 'is false without a file' do
      expect(described_class.fresh?(tm_id)).to be(false)
    end

    it 'is true for a file written now' do
      api_path.write('{}')

      expect(described_class.fresh?(tm_id)).to be(true)
    end

    it 'is false once the file is older than the TTL' do
      api_path.write('{}')
      FileUtils.touch(api_path, mtime: Time.zone.now.to_time - described_class::TTL - 60)

      expect(described_class.fresh?(tm_id)).to be(false)
    end

    it 'is false without a tm_id' do
      expect(described_class.fresh?(nil)).to be(false)
    end

    it 'is false when the cache is switched off' do
      api_path.write('{}')
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TM_SKIP_CACHE').and_return('1')

      expect(described_class.fresh?(tm_id)).to be(false)
    end
  end
end
