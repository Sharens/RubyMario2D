require 'spec_helper'

RSpec.describe ProjectName::Models::User do
  describe '#valid?' do
    it 'returns true when email and name are present' do
      user = described_class.new(email: 'test@example.com', name: 'Test User')
      expect(user.valid?).to be true
    end
  end
end 