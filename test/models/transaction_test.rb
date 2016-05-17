require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test 'validations' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    transaction = transactions(:test_transaction)

    new_transaction = Transaction.new
    new_transaction.plaid_id = 'newid'
    new_transaction.date = transaction.date
    new_transaction.amount = transaction.amount
    new_transaction.name = transaction.name
    new_transaction.category_id = transaction.category_id
    new_transaction.account = account
    new_transaction.vice = vice
    assert new_transaction.save, 'Couldn\'t save valid Transaction'

    # Account
    assert_not transaction.save, 'Saved Transaction without account'
    transaction.account = account

    # Vice
    assert_not transaction.save, 'Saved Transaction without vice'
    transaction.vice = vice
    assert transaction.save, 'Couldn\'t save valid Transaction'

    # Plaid ID
    plaid_id = transaction.plaid_id
    transaction.plaid_id = nil
    assert_not transaction.save, 'Saved Transaction without plaid_id'
    transaction.plaid_id = plaid_id
    new_transaction.plaid_id = 'newid'

    # Date
    date = transaction.date
    transaction.date = nil
    assert_not transaction.save, 'Saved Transaction without date'
    transaction.date = date

    # Amount
    amount = transaction.amount
    transaction.amount = nil
    assert_not transaction.save, 'Saved Transaction without amount'
    transaction.amount = amount

    # Name
    name = transaction.name
    transaction.name = nil
    assert_not transaction.save, 'Saved Transaction without name'
    transaction.name = name

    # Category ID
    category_id = transaction.category_id
    transaction.category_id = nil
    assert_not transaction.save, 'Saved Transaction without category_id'
    transaction.category_id = category_id
  end
end
