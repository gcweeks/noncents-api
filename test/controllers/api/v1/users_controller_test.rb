require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'Ca5hM0n3y'
    @user.generate_token
    @user.create_fund
    @user.address = addresses(:test_address)
    @user.address.save!
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
                          dob: @user.dob,
                          number: @user.number,
                          goal: @user.goal
                        }
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal 24, res['token'].length
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['number'], @user.number
    assert_equal res['email'], 'new@email.com'
    assert_equal res['dob'], @user.dob.to_s
    assert_equal res['invest_percent'], @user.invest_percent
    assert_equal res['goal'], @user.goal
    assert_not_equal res['fund'], nil
  end

  test 'should get me' do
    # Requires auth
    get :get_me
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token
    get :get_me
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['number'], @user.number
    assert_equal res['email'], @user.email
    assert_equal res['dob'], @user.dob.to_s
    assert_equal res['invest_percent'], @user.invest_percent
    assert_equal res['goal'], @user.goal
    assert_not_equal res['fund'], nil
    assert_equal res['address']['line1'], @user.address.line1
    assert_equal res['address']['line2'], @user.address.line2
    assert_equal res['address']['city'], @user.address.city
    assert_equal res['address']['state'], @user.address.state
    assert_equal res['address']['zip'], @user.address.zip
  end

  test 'should update me' do
    # Requires auth
    put :update_me
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token
    fname = 'Test'
    lname = 'User'
    number = '+5555555555'
    invest_percent = 15
    goal = 420
    put :update_me, user: {
      fname: fname,
      lname: lname,
      number: number,
      invest_percent: invest_percent,
      goal: goal
    }
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal res['fname'], fname
    assert_equal res['lname'], lname
    assert_equal res['number'], number
    assert_equal res['invest_percent'], invest_percent
    assert_equal res['goal'], goal
  end

  test 'should get yearly fund' do
    # Requires auth
    get :get_yearly_fund
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # No YearlyFunds have been created at this point
    assert_equal @user.yearly_funds.count, 0

    # Get YearlyFund
    get :get_yearly_fund
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['balance'].to_f, 0.00
    assert_equal res['amount_invested'].to_f, 0.00
    assert_equal res['year'], Date.current.year
    assert_equal res['user_id'], @user.id

    # YearlyFund now created
    assert_equal @user.yearly_funds.count, 1
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
    res = JSON.parse(@response.body)
    assert_equal res['vices'], vices

    # No Vice
    vices = %w(None)
    post :set_vices, vices: vices
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['vices'], []
  end

  test 'should set address' do
    # Requires auth
    post :set_address
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # No line1
    post :set_address, address: { line1: nil,
                                  line2: @user.address.line2,
                                  city: @user.address.city,
                                  state: @user.address.state,
                                  zip: @user.address.zip
                                }
    assert_response :unprocessable_entity

    # No city
    post :set_address, address: { line1: @user.address.line1,
                                  line2: @user.address.line2,
                                  city: nil,
                                  state: @user.address.state,
                                  zip: @user.address.zip
                                }
    assert_response :unprocessable_entity

    # No state
    post :set_address, address: { line1: @user.address.line1,
                                  line2: @user.address.line2,
                                  city: @user.address.city,
                                  state: nil,
                                  zip: @user.address.zip
                                }
    assert_response :unprocessable_entity

    # No zip
    post :set_address, address: { line1: @user.address.line1,
                                  line2: @user.address.line2,
                                  city: @user.address.city,
                                  state: @user.address.state,
                                  zip: nil
                                }
    assert_response :unprocessable_entity

    # Good request
    post :set_address, address: { line1: @user.address.line1,
                                  line2: @user.address.line2,
                                  city: @user.address.city,
                                  state: @user.address.state,
                                  zip: @user.address.zip
                                }
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['address']['line1'], @user.address.line1
    assert_equal res['address']['line2'], @user.address.line2
    assert_equal res['address']['city'], @user.address.city
    assert_equal res['address']['state'], @user.address.state
    assert_equal res['address']['zip'], @user.address.zip

    # Good request (no line2)
    post :set_address, address: { line1: @user.address.line1,
                                  line2: nil,
                                  city: @user.address.city,
                                  state: @user.address.state,
                                  zip: @user.address.zip
                                }
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['address']['line1'], @user.address.line1
    assert_equal res['address']['line2'], nil
    assert_equal res['address']['city'], @user.address.city
    assert_equal res['address']['state'], @user.address.state
    assert_equal res['address']['zip'], @user.address.zip
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
    @user.reload
    assert_equal @user.banks.size, 0
    assert_equal @user.accounts.size, 0
    get :account_connect, username: username, password: password, type: type
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['mfa_type'], 'list'
    @user.reload
    # Bank saved for reference
    assert_equal @user.banks.size, 1
    # Still 0
    assert_equal @user.accounts.size, 0

    # Successfully acquired bank accounts
    type = 'wells' # No MFA
    get :account_connect, username: username, password: password, type: type
    assert_response :success
    @user.reload
    assert_equal @user.banks.size, 2 # chase and wells
    # Has at least one Account now
    assert_not_equal @user.accounts.size, 0
    @user.accounts.each do |account|
      bank = @user.banks.find_by(name: type)
      assert_equal account.bank_id, bank.id
    end
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

    # Send initial call
    get :account_connect, username: 'plaid_test', password: 'plaid_good',
      type: 'chase'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['mfa_type'], 'list'
    @user.reload
    # Bank saved for reference
    assert_equal @user.banks.size, 1
    # Still 0
    assert_equal @user.accounts.size, 0

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
    assert_response :payment_required

    # Needs more MFA
    get :account_mfa, access_token: 'test_usaa', answer: 'again'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['mfa_type'], 'questions'

    # Correct MFA answer
    @user.reload
    # Bank saved for reference
    assert_equal @user.banks.size, 1
    # Still 0
    assert_equal @user.accounts.size, 0
    get :account_mfa, access_token: access_token, answer: answer
    assert_response :success
    @user.reload
    assert_equal @user.banks.size, 1
    # Has at least one Account now
    assert_not_equal @user.accounts.size, 0
    @user.accounts.each do |account|
      bank = @user.banks.find_by(name: 'chase')
      assert_equal account.bank_id, bank.id
    end
  end

  test 'should update and remove accounts' do
    # Requires auth
    put :update_accounts
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Populate initial accounts
    get(:account_connect, username: 'plaid_test',
                          password: 'plaid_good',
                          type: 'wells') # No MFA
    assert_response :success
    @user.reload
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
    account_ids = @user.accounts.map(&:id)

    # Requires one or more of the following: source, deposit, tracking
    put :update_accounts
    assert_response :bad_request

    # Ensure no Account is set yet
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[2])
    assert_equal account.tracking, false

    # Set Accounts
    put :update_accounts, source: account_ids[0], deposit: account_ids[1],
      tracking: [account_ids[0], account_ids[1]]
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, account_ids[0]
    assert_equal @user.deposit_account.id, account_ids[1]
    # Verify that setting tracking was successful
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, true
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true
    account = Account.find_by(id: account_ids[2])
    assert_equal account.tracking, false
    # Idempotency
    put :update_accounts, source: account_ids[0], deposit: account_ids[1],
      tracking: [account_ids[0], account_ids[1]]
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, account_ids[0]
    assert_equal @user.deposit_account.id, account_ids[1]
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, true
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true

    # Remove Accounts
    delete :remove_accounts, source: nil, deposit: 'blah',
      tracking: [account_ids[0], account_ids[1]]
    res = JSON.parse(@response.body)
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    # Verify that setting tracking was successful
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, false

    # Set only Source
    put :update_accounts, source: account_ids[0]
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, account_ids[0]
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, false
    delete :remove_accounts, source: nil
    assert_response :success

    # Set only Deposit
    put :update_accounts, deposit: account_ids[1]
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account.id, account_ids[1]
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, false
    delete :remove_accounts, deposit: nil
    assert_response :success

    # Set only Tracking
    put :update_accounts, tracking: [account_ids[1]]
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true
    delete :remove_accounts, tracking: [account_ids[1]]
    assert_response :success

    # Repopulate
    put :update_accounts, source: account_ids[0], deposit: account_ids[1],
      tracking: [account_ids[0], account_ids[1]]
    assert_response :success

    # Remove only Source
    delete :remove_accounts, source: nil
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account.id, account_ids[1]
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, true
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true
    put :update_accounts, source: account_ids[0]

    # Remove only Deposit
    delete :remove_accounts, deposit: nil
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, account_ids[0]
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, true
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true
    put :update_accounts, deposit: account_ids[1]

    # Remove only Tracking
    delete :remove_accounts, tracking: [account_ids[0]]
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, account_ids[0]
    assert_equal @user.deposit_account.id, account_ids[1]
    account = Account.find_by(id: account_ids[0])
    assert_equal account.tracking, false
    account = Account.find_by(id: account_ids[1])
    assert_equal account.tracking, true
    put :update_accounts, tracking: [account_ids[0]]
  end

  test 'should refresh transactions' do
    # Not implemented
  end

  test 'should register push token' do
    # Requires auth
    post :register_push_token
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Requires a token
    post :register_push_token
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['token'], ['is required']

    # Ensure no token already exists
    fcm_token_string_1 = '1234'
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_equal fcm_token, nil
    assert_not @user.fcm_tokens.include?(fcm_token_string_1)

    # Register token
    post :register_push_token, token: fcm_token_string_1
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['status'], 'registered'

    # Ensure token was successfully registered
    @user.reload
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_1
    assert_equal fcm_token.user_id, @user.id
    assert @user.fcm_tokens.include?(fcm_token_string_1)

    # Add another token
    fcm_token_string_2 = '5678'
    post :register_push_token, token: fcm_token_string_2
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['status'], 'registered'
    @user.reload
    # Ensure User still has both tokens
    # Token 1
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_1
    assert_equal fcm_token.user_id, @user.id
    assert @user.fcm_tokens.include?(fcm_token_string_1)
    # Token 2
    fcm_token = FcmToken.find_by(token: fcm_token_string_2)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_2
    assert_equal fcm_token.user_id, @user.id
    assert @user.fcm_tokens.include?(fcm_token_string_2)

    # Change Token 1 User
    # Create new User
    user_2 = User.new
    user_2.fname = @user.fname
    user_2.lname = @user.lname
    user_2.number = @user.number
    user_2.email = 'new@email.com'
    user_2.dob = @user.dob
    user_2.invest_percent = @user.invest_percent
    user_2.goal = @user.goal
    user_2.password = 'Ca5hM0n3y'
    user_2.generate_token
    user_2.create_fund
    address_2 = Address.new
    address_2.line1 = @user.address.line1
    address_2.line2 = @user.address.line2
    address_2.city = @user.address.city
    address_2.state = @user.address.state
    address_2.zip = @user.address.zip
    address_2.save!
    user_2.address = address_2
    user_2.save!
    @request.headers['Authorization'] = user_2.token
    # Register token
    post :register_push_token, token: fcm_token_string_1
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['status'], 'registered'
    # Ensure user_2 has token
    user_2.reload
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_1
    assert_equal fcm_token.user_id, user_2.id
    assert user_2.fcm_tokens.include?(fcm_token_string_1)
    # Ensure @user no longer has token
    @user.reload
    assert_not @user.fcm_tokens.include?(fcm_token_string_1)
    # @user should still have other token, user_2 should not
    assert @user.fcm_tokens.include?(fcm_token_string_2)
    assert_not user_2.fcm_tokens.include?(fcm_token_string_2)
  end

  test 'should create dwolla account' do
    # Requires auth
    post :dwolla
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Requires ssn
    post :dwolla
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['ssn'], ['is required']

    post :dwolla, ssn: '123-45-6789'
    assert_response :ok

    # No address
    # Store address for later
    address = {
      line1: '@user.address.line1',
      line2: '@user.address.line2',
      city: '@user.address.city',
      state: '@user.address.state',
      zip: '@user.address.zip'
    }
    @user.address.delete
    post :dwolla, ssn: '123-45-6789'
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['address'], ['is required']

    # Address in payload
    post :dwolla, address: address, ssn: '123-45-6789'
    assert_response :ok
    @user.reload
    assert_equal address[:line1], @user.address.line1
    assert_equal address[:line2], @user.address.line2
    assert_equal address[:city], @user.address.city
    assert_equal address[:state], @user.address.state
    assert_equal address[:zip], @user.address.zip
  end

  test 'should refresh transactions dev' do
    # Requires auth
    post :dev_refresh_transactions # TODO Fake transactions
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    assert_equal @user.transactions.size, 0
    get :account_connect, username: 'plaid_test', password: 'plaid_good',
                          type: 'wells'
    assert_response :success
    @user.reload
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now

    # Get transactions without vices
    vices = %w(None)
    post :set_vices, vices: vices
    assert_response :success
    post :dev_refresh_transactions # TODO Fake transactions
    assert_response :success
    @user.reload
    assert_equal @user.transactions.size, 0

    # Get transactions with vice
    vices = %w(CoffeeShops)
    post :set_vices, vices: vices
    assert_response :success
    post :dev_refresh_transactions # TODO Fake transactions
    assert_response :success
    @user.reload
    assert_operator @user.transactions.size, :>, 0
  end

  test 'should populate dev' do
    # Not implemented
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
    @user.reload
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
    vices = %w(CoffeeShops)
    post :set_vices, vices: vices
    assert_response :success
    post :dev_refresh_transactions # TODO Fake transactions
    assert_response :success
    @user.reload
    # Make sure we've got a couple transactions to play with
    assert_operator @user.transactions.size, :>=, 2

    # Back out of one transaction
    backed_out_tx = @user.transactions[0]
    backed_out_tx.backed_out = true
    backed_out_tx.save!

    # Deduct
    assert_equal @user.fund.amount_invested, 0
    assert_equal @user.yearly_fund().amount_invested, 0
    post :dev_deduct
    assert_response :success
    @user.reload
    total_invested = 0
    @user.transactions.each do |tx|
      if tx.id == backed_out_tx.id
        assert_equal tx.invested, false
        assert_equal tx.amount_invested, 0
      else
        assert_equal tx.invested, true
        assert_operator tx.amount_invested, :>, 0
        total_invested += tx.amount_invested
      end
    end
    assert_equal @user.fund.amount_invested, total_invested
    assert_equal @user.yearly_fund().amount_invested, total_invested
  end

  test 'should aggregate funds dev' do
    # Requires auth
    post :dev_aggregate
    assert_response :unauthorized

    @request.headers['Authorization'] = @user.token

    # Get transactions (essentially copy-paste from above)
    assert_equal @user.transactions.size, 0
    get :account_connect, username: 'plaid_test', password: 'plaid_good',
                          type: 'wells'
    assert_response :success
    @user.reload
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now
    vices = %w(CoffeeShops)
    post :set_vices, vices: vices
    assert_response :success
    post :dev_refresh_transactions # TODO Fake transactions
    assert_response :success
    @user.reload
    # Make sure we've got a couple transactions to play with
    assert_operator @user.transactions.size, :>=, 2

    # Deduct
    assert_equal @user.fund.amount_invested, 0.00
    assert_equal @user.yearly_fund().amount_invested, 0.00
    post :dev_deduct
    assert_response :success
    @user.reload
    last_month = Date.current.beginning_of_month - 1.month
    amount = 0.00 # Keep track of total amount invested
    @user.transactions.each do |tx|
      assert_equal tx.invested, true
      amount += tx.amount_invested
      # Force date to be last month
      tx.date = last_month
      tx.save!
    end
    assert_not_equal amount, 0.00
    assert_equal @user.fund.amount_invested, amount
    assert_equal @user.yearly_fund().amount_invested, amount

    assert_equal @user.agexes.size, 0
    post :dev_aggregate
    assert_response :success
    @user.reload
    assert_equal @user.agexes.size, 1
    agex = @user.agexes.first
    assert_equal agex.month, last_month
    assert_equal agex.amount, amount
    assert_equal agex.vice, vices(:coffeeshops)
    assert_equal agex.user, @user
  end

  test 'should notify dev' do
    # Not implemented
  end
end
