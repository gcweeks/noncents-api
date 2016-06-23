require 'test_helper'

class YearlyFundTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)
    yearly_fund = YearlyFund.new
    yearly_fund.year = 2016

    # User
    assert_not yearly_fund.save, 'Saved YearlyFund without user'
    yearly_fund.user = user
    assert yearly_fund.save, 'Couldn\'t save valid YearlyFund'

    # Year
    year = yearly_fund.year
    yearly_fund.year = nil
    assert_not yearly_fund.save, 'Saved YearlyFund without year'
    yearly_fund.year = year
    yearly_fund.save!

    # Balance
    yearly_fund.balance = -0.01
    assert_not yearly_fund.save, 'Saved YearlyFund with negative balance'
    yearly_fund.balance = 0
    yearly_fund.amount_invested = -1
    assert_not(yearly_fund.save,
               'Saved YearlyFund with negative amount_invested')
    yearly_fund.amount_invested = 0

    # Deposit
    invested = yearly_fund.amount_invested
    amount = 1.23
    yearly_fund.deposit! amount
    assert_equal(invested + amount, yearly_fund.amount_invested,
                 'Didn\'t correctly deposit money')

    # Negative deposit
    invested = yearly_fund.amount_invested
    amount = -1.23
    yearly_fund.deposit! amount
    assert_equal(invested, yearly_fund.amount_invested,
                 'Deposited negative amount')
  end
end
