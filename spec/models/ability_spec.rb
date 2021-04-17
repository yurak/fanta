require 'cancan/matchers'

RSpec.describe Ability, type: :model do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:user) }

  describe 'user with customer role' do
    it 'can not access to rails_admin' do
      expect(ability).not_to be_able_to(:access, :rails_admin)
    end

    it 'can not read dashboard' do
      expect(ability).not_to be_able_to(:read, :dashboard)
    end

    it 'can not manage all' do
      expect(ability).not_to be_able_to(:manage, :all)
    end
  end

  describe 'user with moderator role' do
    let(:user) { create(:moderator) }

    it 'can not access to rails_admin' do
      expect(ability).not_to be_able_to(:access, :rails_admin)
    end

    it 'can not read dashboard' do
      expect(ability).not_to be_able_to(:read, :dashboard)
    end

    it 'can not manage all' do
      expect(ability).not_to be_able_to(:manage, :all)
    end
  end

  describe 'user with admin role' do
    let(:user) { create(:admin) }

    it 'can access to rails_admin' do
      expect(ability).to be_able_to(:access, :rails_admin)
    end

    it 'can read dashboard' do
      expect(ability).to be_able_to(:read, :dashboard)
    end

    it 'can manage all' do
      expect(ability).to be_able_to(:manage, :all)
    end
  end
end
