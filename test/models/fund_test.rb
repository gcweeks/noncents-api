require 'test_helper'

class FundTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)
    fund = Fund.new

    # User
    assert_not fund.save, 'Saved Fund without user'
    fund.user = user
    assert fund.save, 'Couldn\'t save valid Fund'

    # Balance
    fund.balance = -0.01
    assert_not fund.save, 'Saved Fund with negative balance'
    fund.balance = 0
    fund.amount_invested = -1
    assert_not fund.save, 'Saved Fund with negative amount_invested'
    fund.amount_invested = 0

    # Deposit
    invested = fund.amount_invested
    amount = 1.23
    fund.deposit! amount
    assert_equal(invested + amount, fund.amount_invested,
                 'Didn\'t correctly deposit money')

    # Negative deposit
    invested = fund.amount_invested
    amount = -1.23
    fund.deposit! amount
    assert_equal invested, fund.amount_invested, 'Deposited negative amount'
  end
end
