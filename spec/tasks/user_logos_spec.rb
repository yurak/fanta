# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

Rake.application.rake_require('tasks/user_logos')
Rake::Task.define_task(:environment)

RSpec.describe 'user_logos rake tasks' do
  describe 'user_logos:backfill' do
    let(:bucket_url) { 'https://test-bucket.example.com' }
    let(:default_url) { "#{bucket_url}/teams/default_icons/default1.png" }
    let(:custom_url) { "#{bucket_url}/user_logos/1/abc.png" }
    let(:user) { create(:user) }

    before do
      allow(S3Storage).to receive(:bucket_url).and_return(bucket_url)
      Rake::Task['user_logos:backfill'].reenable
    end

    it 'creates an approved logo for a team with a custom logo' do
      create(:team, :with_user, user: user, logo_url: custom_url)
      Rake::Task['user_logos:backfill'].invoke
      expect(user.user_logos.approved.pluck(:url)).to eq([custom_url])
    end

    it 'skips default icons' do
      create(:team, :with_user, user: user, logo_url: default_url)
      Rake::Task['user_logos:backfill'].invoke
      expect(user.user_logos.count).to eq(0)
    end

    it 'creates a single logo when the same url is used by several teams' do
      create(:team, :with_user, user: user, logo_url: custom_url)
      create(:team, :with_user, user: user, logo_url: custom_url)
      Rake::Task['user_logos:backfill'].invoke
      expect(user.user_logos.where(url: custom_url).count).to eq(1)
    end

    it 'does not duplicate an existing logo' do
      create(:team, :with_user, user: user, logo_url: custom_url)
      create(:user_logo, user: user, url: custom_url, status: :approved)
      Rake::Task['user_logos:backfill'].invoke
      expect(user.user_logos.where(url: custom_url).count).to eq(1)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
