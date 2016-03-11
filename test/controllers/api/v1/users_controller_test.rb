require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'cashmoney'
    @user.generate_token
    @user.create_fund
    @user.save!
  end

  test 'should create' do
    # Missing email
    post :create, user: { password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid email
    post :create, user: { email: 'bad@email',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Existing email
    post :create, user: { email: @user.email,
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing password
    post :create, user: { email: 'new@email.com',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid password
    post :create, user: { email: 'new@email.com',
                          password: 'short',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing fname
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing lname
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: -1,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: 101,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing dob
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent
                        }
    assert_response :unprocessable_entity
    # Valid User
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :success

    # Check Token
    res = JSON.parse(@response.body)
    assert_equal 24, res['token'].length
  end

  test 'should get me' do
    # Requires auth
    get :get_me
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token
    get :get_me
    assert_response :success
  end

  test 'should update me' do
    # Requires auth
    put :update_me
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token
    fname = 'Test'
    put :update_me, user: { fname: fname }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['fname'], fname
  end

  test 'should set vices' do
    # Requires auth
    post :set_vices
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Nil Vice
    post :set_vices
    assert_response :bad_request

    # Bad format
    vices = 'badformat'
    post :set_vices, vices: vices
    assert_response :bad_request

    # Non-existent Vice
    vices = %w(IDontExist)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity
    vices = %w(Travel IDontExist)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity
    vices = %w(IDontExist Travel)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity

    # Correct Vices
    vices = %w(Travel Nightlife)
    post :set_vices, vices: vices
    assert_response :success
    assert_equal JSON(@response.body)['vices'], vices

    # No Vice
    vices = %w(None)
    post :set_vices, vices: vices
    assert_response :success
    assert_equal JSON(@response.body)['vices'], []
  end

  test 'should connect to plaid' do
    username = 'plaid_test'
    password = 'plaid_good'
    type = 'chase'

    # Requires auth
    get :account_connect
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Requires username, password, and type
    get :account_connect
    assert_response :bad_request
    get :account_connect, username: username, password: password
    assert_response :bad_request
    get :account_connect, type: type, password: password
    assert_response :bad_request
    get :account_connect, username: username, type: type
    assert_response :bad_request

    # MFA
    @user = User.find_by(id: @user.id)
    assert_equal @user.accounts.size, 0
    get :account_connect, username: username, password: password, type: type
    assert_response :success
    assert_equal JSON(@response.body)['api_res'],
                 'Requires further authentication'
    @user = User.find_by(id: @user.id)
    assert_equal @user.accounts.size, 0 # Still 0

    # Successfully acquired bank accounts
    type = 'wells' # No MFA
    get :account_connect, username: username, password: password, type: type
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
  end

  test 'should mfa with plaid' do
    access_token = 'test_chase'
    type = 'email'
    mask = 'xxx-xxx-5309'
    answer = '1234'

    # Requires auth
    get :account_mfa
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Requires access_token and either answer, mask, or type
    get :account_mfa
    assert_response :bad_request
    get :account_mfa, access_token: access_token
    assert_response :bad_request

    # Set MFA method
    get :account_mfa, access_token: access_token, type: type
    assert_response :success
    get :account_mfa, access_token: access_token, mask: mask
    assert_response :success

    # Incorrect MFA answer
    get :account_mfa, access_token: access_token, answer: 'wrong'
    assert_response :unauthorized

    # Needs more MFA
    get :account_mfa, access_token: 'test_usaa', answer: 'again'
    assert_response :success
    assert_equal JSON(@response.body)['api_res'],
                 'Requires further authentication'

    # Correct MFA answer
    @user = User.find_by(id: @user.id)
    assert_equal @user.accounts.size, 0 # Still 0
    get :account_mfa, access_token: access_token, answer: answer
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
  end

  test 'should remove accounts' do
    # Requires auth
    put :remove_accounts
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Populate initial accounts
    get(:account_connect, username: 'plaid_test',
                          password: 'plaid_good',
                          type: 'wells') # No MFA
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
    account_ids = @user.accounts.map(&:id)

    # Requires at least one account
    put :remove_accounts
    assert_response :bad_request

    # Requires accounts to be in array format
    put :remove_accounts, accounts: account_ids[0]
    assert_response :bad_request

    # Remove 1 account
    put :remove_accounts, accounts: [account_ids[0]]
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_equal account_ids.size - @user.accounts.size, 1
    new_ids = @user.accounts.map(&:id)
    assert_not_includes new_ids, account_ids[0]
    assert_includes new_ids, account_ids[1]
    assert_includes new_ids, account_ids[2]
    assert_includes new_ids, account_ids[3]

    # Remove multiple accounts
    put :remove_accounts, accounts: [account_ids[1], account_ids[2]]
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_equal account_ids.size - @user.accounts.size, 3
    new_ids = @user.accounts.map(&:id)
    assert_not_includes new_ids, account_ids[0]
    assert_not_includes new_ids, account_ids[1]
    assert_not_includes new_ids, account_ids[2]
    assert_includes new_ids, account_ids[3]
  end

  test 'should refresh transactions' do
    # Requires auth
    get :refresh_transactions
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    assert_equal @user.transactions.size, 0
    get :account_connect, username: 'plaid_test', password: 'plaid_good',
                          type: 'wells'
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now

    # Get transactions without vices
    vices = %w(None)
    post :set_vices, vices: vices
    assert_response :success
    get :refresh_transactions
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_equal @user.transactions.size, 0

    # Get transactions with vice
    vices = %w(CoffeeShops)
    post :set_vices, vices: vices
    assert_response :success
    get :refresh_transactions
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_operator @user.transactions.size, :>, 0
  end

  test 'should deduct into funds dev' do
    # Requires auth
    post :dev_deduct
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Get transactions (essentially copy-paste from above)
    assert_equal @user.transactions.size, 0
    get :account_connect, username: 'plaid_test', password: 'plaid_good',
                          type: 'wells'
    assert_response :success
    @user = User.find_by(id: @user.id)
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
    vices = %w(CoffeeShops)
    post :set_vices, vices: vices
    assert_response :success
    get :refresh_transactions
    assert_response :success
    @user = User.find_by(id: @user.id)
    # Make sure we've got a couple transactions to play with
    assert_operator @user.transactions.size, :>=, 2

    # Back out of one transaction
    backed_out_tx = @user.transactions[0]
    backed_out_tx.backed_out = true
    backed_out_tx.save!

    # Deduct
    assert_equal @user.fund.amount_invested, 0
    post :dev_deduct
    assert_response :success
    @user = User.find_by(id: @user.id)
    @user.transactions.each do |tx|
      if tx.id == backed_out_tx.id
        assert_equal tx.invested, false
      else
        assert_equal tx.invested, true
      end
    end
  end
end
