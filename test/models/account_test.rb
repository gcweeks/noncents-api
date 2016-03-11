require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'validations' do
    account = accounts(:test_account)
    assert account.save, 'Couldn\'t save valid Account'

    # Plaid ID
    plaid_id = account.plaid_id
    account.plaid_id = nil
    assert_not account.save, 'Saved Account without plaid_id'
    account.plaid_id = plaid_id

    # Name
    name = account.name
    account.name = nil
    assert_not account.save, 'Saved Account without name'
    account.name = name

    # Account type
    account_type = account.account_type
    account.account_type = nil
    assert_not account.save, 'Saved Account without account_type'
    account.account_type = account_type

    # Institution
    institution = account.institution
    account.institution = nil
    assert_not account.save, 'Saved Account without institution'
    account.institution = institution
  end
end
