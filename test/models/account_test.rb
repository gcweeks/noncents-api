require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'validations' do
    account = accounts(:test_account)
    assert account.save, 'Couldn\'t save valid Account'

    # Plaid ID
    plaid_id = transaction.plaid_id
    transaction.plaid_id = nil
    assert_not transaction.save, 'Saved Transaction without plaid_id'
    transaction.plaid_id = plaid_id

    # Name
    name = transaction.name
    transaction.name = nil
    assert_not transaction.save, 'Saved Transaction without name'
    transaction.name = name

    # Account type
    account_type = transaction.account_type
    transaction.account_type = nil
    assert_not transaction.save, 'Saved Transaction without account_type'
    transaction.account_type = account_type

    # Institution
    institution = transaction.institution
    transaction.institution = nil
    assert_not transaction.save, 'Saved Transaction without institution'
    transaction.institution = institution
  end
end
