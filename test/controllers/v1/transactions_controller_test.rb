require 'test_helper'

class V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/transactions/'
    @user = users(:cashmoney)
    @user.password = 'Ca5hM0n3y'
    @user.generate_token
    @user.create_fund
    @user.save!
    @headers = { 'Authorization' => @user.token }
  end

  # Both 'back_out' and 'restore' routes are handled by this test
  test 'should back out and restore' do
    # Create fake transaction
    account = accounts(:test_account)
    vice = vices(:nightlife)
    back_out_tx = transactions(:test_transaction)
    back_out_tx.account = account
    back_out_tx.vice = vice
    back_out_tx.user = @user
    back_out_tx.save!
    assert_equal back_out_tx.backed_out, false

    # Requires auth
    post back_out_tx.id + '/back_out'
    assert_response :unauthorized
    post back_out_tx.id + '/restore'
    assert_response :unauthorized

    # Try backing out of a transaction that doesn't belong to @user
    new_user = User.new(fname: 'Different', lname: 'Person', dob: '1990-01-20',
                        phone: '5555552017', invest_percent: 10,
                        password: 'Ca5hM0n3y', email: 'different@email.com')
    new_user.generate_token
    new_user.create_fund
    new_user.password = 'Ca5hM0n3y'
    new_user.save!
    back_out_tx.user = new_user
    back_out_tx.save!
    post back_out_tx.id + '/back_out', headers: @headers
    assert_response :not_found
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false

    # Add to @user
    back_out_tx.user = @user
    back_out_tx.save!
    # Back out
    post back_out_tx.id + '/back_out', headers: @headers
    assert_response :success
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, true
    # Restore
    post back_out_tx.id + '/restore', headers: @headers
    assert_response :success
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false

    # Archive Transaction
    back_out_tx.archived = true
    back_out_tx.save!
    # Back out
    back_out_tx.backed_out = false
    back_out_tx.save!
    post back_out_tx.id + '/back_out', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['transaction'], ['has already been archived']
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false
    # Restore
    back_out_tx.backed_out = true
    back_out_tx.save!
    post back_out_tx.id + '/restore', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['transaction'], ['has already been archived']
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, true

    # Invest Transaction
    back_out_tx.archived = false
    back_out_tx.invested = true
    back_out_tx.save!
    # Back out
    back_out_tx.backed_out = false
    back_out_tx.save!
    post back_out_tx.id + '/back_out', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['transaction'], ['has already been invested']
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false
    # Restore
    back_out_tx.backed_out = true
    back_out_tx.save!
    post back_out_tx.id + '/restore', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['transaction'], ['has already been invested']
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, true
  end
end
