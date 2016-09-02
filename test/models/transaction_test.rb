require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test 'validations' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    user = users(:cashmoney)
    user.generate_token
    user.create_fund
    user.password = 'Ca5hM0n3y'
    user.save!
    transaction = transactions(:test_transaction)
    transaction.plaid_id = 'newid'
    transaction.account = account
    transaction.vice = vice
    transaction.user = user
    assert transaction.save, 'Couldn\'t save valid Transaction'

    # Account
    transaction.account = nil
    assert_not transaction.save, 'Saved Transaction without account'
    transaction.account = account

    # User
    transaction.user = nil
    assert_not transaction.save, 'Saved Transaction without user'
    transaction.user = user

    # Vice
    transaction.vice = nil
    assert_not transaction.save, 'Saved Transaction without vice'
    transaction.vice = vice
    assert transaction.save, 'Couldn\'t save valid Transaction'

    # Plaid ID
    plaid_id = transaction.plaid_id
    transaction.plaid_id = nil
    assert_not transaction.save, 'Saved Transaction without plaid_id'
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

    assert transaction.save, 'Couldn\'t save valid Transaction'
  end

  test 'should create from plaid' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    user = users(:cashmoney)
    user.generate_token
    user.create_fund
    user.password = 'Ca5hM0n3y'
    user.save!
    Struct.new("PlaidTransaction", :id, :date, :amount, :name, :category_id)
    plaid_transaction = Struct::PlaidTransaction.new("1234", Date.current,
      12.34, 'A transaction', '5678')

    transaction = Transaction.from_plaid(plaid_transaction)
    transaction.account = account
    transaction.vice = vice
    transaction.user = user
    assert transaction.save, 'Couldn\'t save valid Transaction'

    assert_equal transaction.plaid_id, plaid_transaction.id
    assert_equal transaction.date, plaid_transaction.date
    assert_equal transaction.amount, plaid_transaction.amount
    assert_equal transaction.name, plaid_transaction.name
    assert_equal transaction.category_id, plaid_transaction.category_id
  end

  test 'should invest' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    user = users(:cashmoney)
    user.generate_token
    user.create_fund
    user.password = 'Ca5hM0n3y'
    user.save!
    transaction = transactions(:test_transaction)
    transaction.account = account
    transaction.vice = vice
    transaction.user = user
    transaction.invested = false
    transaction.save!

    transaction.invest!(4.56)
    transaction.reload
    assert transaction.invested, 'Couldn\'t invest Transaction'
    assert_equal transaction.amount_invested, 4.56
  end

  test 'should archive' do
    account = accounts(:test_account)
    vice = vices(:nightlife)
    user = users(:cashmoney)
    user.generate_token
    user.create_fund
    user.password = 'Ca5hM0n3y'
    user.save!
    transaction = transactions(:test_transaction)
    transaction.account = account
    transaction.vice = vice
    transaction.user = user
    transaction.archived = false
    transaction.save!

    transaction.reload
    assert_not transaction.archived, 'Transaction already archived'
    transaction.archive!
    transaction.reload
    assert transaction.archived, 'Couldn\'t archive Transaction'
  end
end
