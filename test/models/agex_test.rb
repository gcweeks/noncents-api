require 'test_helper'

class AgexTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)
    vice = vices(:nightlife)
    agex = Agex.new
    agex.month = Date.current.beginning_of_month
    agex.vice = vice

    # User
    assert_not agex.save, 'Saved Agex without user'
    agex.user = user

    # Vice
    agex.vice = nil
    assert_not agex.save, 'Saved Agex without vice'
    agex.vice = vice

    # Month
    month = agex.month
    agex.month = nil
    assert_not agex.save, 'Saved Agex without month'
    agex.month = month

    assert agex.save, "Couldn't save valid Agex"

    # Balance
    agex.amount = -0.01
    assert_not agex.save, 'Saved Agex with negative balance'
    agex.amount = 0
    assert agex.save, "Couldn't save valid Agex"
  end
end
