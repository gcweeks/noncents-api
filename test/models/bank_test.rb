require 'test_helper'

class BankTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)
    bank = banks(:test_bank)

    # User
    assert_not bank.save, 'Saved Bank without User'
    bank.user = user
    assert bank.save, 'Couldn\'t save valid Bank'

    # Name
    name = bank.name
    bank.name = nil
    assert_not bank.save, 'Saved Bank without name'
    bank.name = name

    # Access token
    access_token = bank.access_token
    bank.access_token = nil
    assert_not bank.save, 'Saved Bank without access_token'
    bank.access_token = access_token
  end
end
