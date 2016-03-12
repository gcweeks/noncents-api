require 'test_helper'

class Api::V1::TransactionsControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'Ca5hM0n3y'
    @user.generate_token
    @user.create_fund
    @user.save!
  end

  # Both back_out and invest routes are handled by this test
  test 'should back out and invest' do
    # Create fake transaction
    account = accounts(:test_account)
    vice = vices(:nightlife)
    back_out_tx = transactions(:test_transaction)
    back_out_tx.account = account
    back_out_tx.vice = vice
    back_out_tx.save!
    assert_equal back_out_tx.backed_out, false

    # Requires auth
    post :back_out, id: back_out_tx.id
    assert_response :unauthorized
    post :invest, id: back_out_tx.id
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Try backing out of a transaction that doesn't belong to @user
    post :back_out, id: back_out_tx.id
    assert_response :not_found
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false

    # Add to @user
    @user.transactions << back_out_tx

    # Back out
    post :back_out, id: back_out_tx.id
    assert_response :success
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, true

    # Invest
    post :invest, id: back_out_tx.id
    assert_response :success
    back_out_tx = Transaction.find_by(id: back_out_tx.id)
    assert_equal back_out_tx.backed_out, false
  end
end
