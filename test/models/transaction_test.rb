require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test 'validations' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    transaction = transaction(:test_transaction)

    # Account
    assert_not transaction.save, 'Saved Transaction without account'
    transaction.account = account

    # Vice
    assert_not transaction.save, 'Saved Transaction without vice'
    transaction.vice = vice
    assert transaction.save, 'Couldn\'t save valid Transaction'

    # Plaid transaction building
    plaid_transaction = {}
    plaid_transaction['id'] = '0AZ0De04KqsreDgVwM1RSRYjyd8yXxSDQ8Zxn'
    plaid_transaction['date'] = '2014-07-21'
    plaid_transaction['amount'] = 200
    plaid_transaction['name'] = 'ATM Withdrawal'
    plaid_transaction['category_id'] = '21012002'
    plaid_transaction['account'] = 'XARE85EJqKsjxLp6XR8ocg8VakrkXpTXmRdOo'

    new_transaction = Transaction.create_from_plaid plaid_transaction
    new_transaction.account = account
    new_transaction.vice = vice
    assert new_transaction.save, 'Couldn\'t save plaid Transaction'

    # Plaid ID
    plaid_id = transaction.plaid_id
    transaction.plaid_id = new_transaction.plaid_id
    assert_not transaction.save, 'Saved Transaction with duplicate plaid_id'
    transaction.plaid_id = plaid_id

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
