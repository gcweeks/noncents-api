require 'test_helper'

class V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/users/'
    @user = users(:cashmoney)
    @user.password = 'Ca5hM0n3y'
    @user.generate_token
    @user.create_fund
    @user.address = addresses(:test_address)
    @user.address.save!
    @user.save!
    @headers = { 'Authorization' => @user.token }
  end

  test 'should create' do
    # Missing email
    post '/', params: { user: { password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Invalid email
    post '/', params: { user: { email: 'bad@email',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Existing email
    post '/', params: { user: { email: @user.email,
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Missing password
    post '/', params: { user: { email: 'new@email.com',
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Invalid password
    post '/', params: { user: { email: 'new@email.com',
                                password: 'short',
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Missing fname
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Missing lname
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: -1,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: 101,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Missing dob
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :unprocessable_entity
    # Missing phone
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal
                              } }
    assert_response :unprocessable_entity
    # Valid User
    post '/', params: { user: { email: 'new@email.com',
                                password: @user.password,
                                fname: @user.fname,
                                lname: @user.lname,
                                invest_percent: @user.invest_percent,
                                dob: @user.dob,
                                goal: @user.goal,
                                phone: @user.phone
                              } }
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal 24, res['token'].length
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['email'], 'new@email.com'
    assert_equal res['dob'], @user.dob.to_s
    assert_equal res['invest_percent'], @user.invest_percent
    assert_equal res['goal'], @user.goal
    assert_equal res['phone'], @user.phone
    assert_not_equal res['fund'], nil
  end

  test 'should get me' do
    # Requires auth
    get 'me'
    assert_response :unauthorized

    get 'me', headers: @headers
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['email'], @user.email
    assert_equal res['dob'], @user.dob.to_s
    assert_equal res['invest_percent'], @user.invest_percent
    assert_equal res['goal'], @user.goal
    assert_equal res['phone'], @user.phone
    assert_not_equal res['fund'], nil
    assert_equal res['address']['line1'], @user.address.line1
    assert_equal res['address']['line2'], @user.address.line2
    assert_equal res['address']['city'], @user.address.city
    assert_equal res['address']['state'], @user.address.state
    assert_equal res['address']['zip'], @user.address.zip
  end

  test 'should update me' do
    # Requires auth
    put 'me'
    assert_response :unauthorized

    fname = 'Test'
    lname = 'User'
    invest_percent = 15
    goal = 420
    phone = '5555555555'
    put 'me', headers: @headers, params: {
      user: {
        fname: fname,
        lname: lname,
        invest_percent: invest_percent,
        goal: goal,
        phone: phone
      }
    }
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal res['fname'], fname
    assert_equal res['lname'], lname
    assert_equal res['invest_percent'], invest_percent
    assert_equal res['goal'], goal
    assert_equal res['phone'], phone
  end

  test 'should get yearly fund' do
    # Requires auth
    get 'me/yearly_fund'
    assert_response :unauthorized

    # No YearlyFunds have been created at this point
    assert_equal @user.yearly_funds.count, 0

    # Get YearlyFund
    get 'me/yearly_fund', headers: @headers
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['balance'].to_f, 0.00
    assert_equal res['amount_invested'].to_f, 0.00
    assert_equal res['year'], Date.current.year

    # YearlyFund now created
    assert_equal @user.yearly_funds.count, 1
  end

  test 'should set vices' do
    # Requires auth
    put 'me/vices'
    assert_response :unauthorized

    # Nil Vice
    put 'me/vices', headers: @headers
    assert_response :bad_request

    # Bad format
    vices = 'badformat'
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :bad_request

    # Non-existent Vice
    vices = %w(IDontExist)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :unprocessable_entity
    vices = %w(Travel IDontExist)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :unprocessable_entity
    vices = %w(IDontExist Travel)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :unprocessable_entity

    # Correct Vices
    vices = %w(Travel Nightlife)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['vices'], vices

    # No Vice
    vices = %w(None)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['vices'], []
  end

  test 'should set address' do
    # Requires auth
    put 'me/address'
    assert_response :unauthorized

    address_orig = {
      line1: @user.address.line1,
      line2: @user.address.line2,
      city: @user.address.city,
      state: @user.address.state,
      zip: @user.address.zip
    }

    address = address_orig.clone

    # No line1
    address[:line1] = nil
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :unprocessable_entity
    address[:line1] = address_orig[:line1]

    # No city
    address[:city] = nil
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :unprocessable_entity
    address[:city] = address_orig[:city]

    # No state
    address[:state] = nil
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :unprocessable_entity
    address[:state] = address_orig[:state]

    # No zip
    address[:zip] = nil
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :unprocessable_entity
    address[:zip] = address_orig[:zip]

    # Good request
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['address']['line1'], @user.address.line1
    assert_equal res['address']['line2'], @user.address.line2
    assert_equal res['address']['city'], @user.address.city
    assert_equal res['address']['state'], @user.address.state
    assert_equal res['address']['zip'], @user.address.zip

    # Good request (no line2)
    address[:line2] = nil
    put 'me/address', headers: @headers, params: { address: address }
    assert_response :ok
    address[:line2] = address_orig[:line2]
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
    get 'me/account_connect'
    assert_response :unauthorized

    # Requires username, password, and type
    get 'me/account_connect', headers: @headers
    assert_response :bad_request
    get 'me/account_connect', headers: @headers, params: {
      username: username,
      password: password
    }
    assert_response :bad_request
    get 'me/account_connect', headers: @headers, params: {
      type: type,
      password: password
    }
    assert_response :bad_request
    get 'me/account_connect', headers: @headers, params: {
      username: username,
      type: type
    }
    assert_response :bad_request

    # MFA
    @user.reload
    assert_equal @user.banks.size, 0
    assert_equal @user.accounts.size, 0
    get 'me/account_connect', headers: @headers, params: {
      username: username,
      password: password,
      type: type
    }
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
    get 'me/account_connect', headers: @headers, params: {
      username: username,
      password: password,
      type: type
    }
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
    get 'me/account_mfa'
    assert_response :unauthorized

    # Send initial call
    get 'me/account_connect', headers: @headers, params: {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'chase'
    }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['mfa_type'], 'list'
    @user.reload
    # Bank saved for reference
    assert_equal @user.banks.size, 1
    # Still 0
    assert_equal @user.accounts.size, 0

    # Requires access_token and either answer, mask, or type
    get 'me/account_mfa', headers: @headers
    assert_response :bad_request
    get 'me/account_mfa', headers: @headers, params: { access_token: access_token }
    assert_response :bad_request

    # Set MFA method
    get 'me/account_mfa', headers: @headers, params: {
      access_token: access_token,
      type: type
    }
    assert_response :success
    get 'me/account_mfa', headers: @headers, params: {
      access_token: access_token,
      mask: mask
    }
    assert_response :success

    # Incorrect MFA answer
    get 'me/account_mfa', headers: @headers, params: {
      access_token: access_token,
      answer: 'wrong'
    }
    assert_response :payment_required

    # Needs more MFA
    get 'me/account_mfa', headers: @headers, params: {
      access_token: 'test_usaa',
      answer: 'again'
    }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['mfa_type'], 'questions'

    # Correct MFA answer
    @user.reload
    # Bank saved for reference
    assert_equal @user.banks.size, 1
    # Still 0
    assert_equal @user.accounts.size, 0
    get 'me/account_mfa', headers: @headers, params: {
      access_token: access_token,
      answer: answer
    }
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
    put 'me/accounts'
    assert_response :unauthorized

    # Populate initial accounts
    get 'me/account_connect', headers: @headers, params: {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'wells' # No MFA
    }
    assert_response :success
    @user.reload
    # Has checking/savings now
    checking = @user.accounts.find_by(account_subtype: 'checking')
    assert_not_equal checking, nil
    savings = @user.accounts.find_by(account_subtype: 'savings')
    assert_not_equal savings, nil

    # Requires one or more of the following: source, deposit, tracking
    put 'me/accounts', headers: @headers
    assert_response :bad_request

    # Ensure no Account is set yet
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, false

    # Requires Dwolla to be authed
    put 'me/accounts', headers: @headers, params: {
      source: checking.id,
      deposit: savings.id,
      tracking: [checking.id, savings.id]
    }
    assert_response :bad_request
    post 'me/dwolla', headers: @headers, params: { ssn: '123-45-6789' }
    assert_response :ok

    # Set Accounts
    put 'me/accounts', headers: @headers, params: {
      source: checking.id,
      deposit: savings.id,
      tracking: [checking.id, savings.id]
    }
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, checking.id
    assert_equal @user.deposit_account.id, savings.id
    # Verify that setting tracking was successful
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, true
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true

    # Idempotency
    put 'me/accounts', headers: @headers, params: {
      source: checking.id,
      deposit: savings.id,
      tracking: [checking.id, savings.id]
    }
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, checking.id
    assert_equal @user.deposit_account.id, savings.id
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, true
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true

    # Remove Accounts
    delete 'me/accounts', headers: @headers, params: {
      source: nil,
      deposit: 'blah',
      tracking: [checking.id, savings.id]
    }
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    # Verify that setting tracking was successful
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, false

    # Set only Source
    put 'me/accounts', headers: @headers, params: { source: checking.id }
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, checking.id
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, false
    delete 'me/accounts', headers: @headers, params: { source: nil }
    assert_response :success

    # Set only Deposit
    put 'me/accounts', headers: @headers, params: { deposit: savings.id }
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account.id, savings.id
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, false
    delete 'me/accounts', headers: @headers, params: { deposit: nil }
    assert_response :success

    # Set only Tracking
    put 'me/accounts', headers: @headers, params: { tracking: [savings.id] }
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true
    delete 'me/accounts', headers: @headers, params: {
      tracking: [savings.id]
    }
    assert_response :success

    # Repopulate
    put 'me/accounts', headers: @headers, params: {
      source: checking.id,
      deposit: savings.id,
      tracking: [checking.id, savings.id]
    }
    assert_response :success

    # Remove only Source
    delete 'me/accounts', headers: @headers, params: { source: nil }
    assert_response :success
    @user.reload
    assert_equal @user.source_account, nil
    assert_equal @user.deposit_account.id, savings.id
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, true
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true
    put 'me/accounts', headers: @headers, params: { source: checking.id }

    # Remove only Deposit
    delete 'me/accounts', headers: @headers, params: { deposit: nil }
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, checking.id
    assert_equal @user.deposit_account, nil
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, true
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true
    put 'me/accounts', headers: @headers, params: { deposit: savings.id }

    # Remove only Tracking
    delete 'me/accounts', headers: @headers, params: {
      tracking: [checking.id]
    }
    assert_response :success
    @user.reload
    assert_equal @user.source_account.id, checking.id
    assert_equal @user.deposit_account.id, savings.id
    account = Account.find_by(id: checking.id)
    assert_equal account.tracking, false
    account = Account.find_by(id: savings.id)
    assert_equal account.tracking, true
    put 'me/accounts', headers: @headers, params: { tracking: [checking.id] }
  end

  test 'should refresh transactions' do
    # Not implemented
  end

  test 'should register push token' do
    # Requires auth
    post 'me/register_push_token'
    assert_response :unauthorized

    # Requires a token
    post 'me/register_push_token', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['token'], ['is required']

    # Ensure no token already exists
    fcm_token_string_1 = '1234'
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_equal fcm_token, nil

    # Register token
    post 'me/register_push_token', headers: @headers, params: {
      token: fcm_token_string_1
    }
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['status'], 'registered'

    # Ensure token was successfully registered
    @user.reload
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_1
    assert_equal fcm_token.user_id, @user.id

    # Add another token
    fcm_token_string_2 = '5678'
    post 'me/register_push_token', headers: @headers, params: {
      token: fcm_token_string_2
    }
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
    # Token 2
    fcm_token = FcmToken.find_by(token: fcm_token_string_2)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_2
    assert_equal fcm_token.user_id, @user.id

    # Change Token 1 User
    # Create new User
    user_2 = User.new
    user_2.fname = @user.fname
    user_2.lname = @user.lname
    user_2.email = 'new@email.com'
    user_2.dob = @user.dob
    user_2.invest_percent = @user.invest_percent
    user_2.goal = @user.goal
    user_2.phone = @user.phone
    user_2.password = 'Ca5hM0n3y'
    user_2.generate_token
    user_2.create_fund
    address_2 = Address.new
    address_2.line1 = @user.address.line1
    address_2.line2 = @user.address.line2
    address_2.city = @user.address.city
    address_2.state = @user.address.state
    address_2.zip = @user.address.zip
    user_2.address = address_2
    address_2.save!
    user_2.save!
    # Register token
    user_2_headers = { 'Authorization' => user_2.token }
    post 'me/register_push_token', headers: user_2_headers, params: {
      token: fcm_token_string_1
    }
    assert_response :ok
    res = JSON.parse(@response.body)
    assert_equal res['status'], 'registered'
    # Ensure user_2 has token
    user_2.reload
    fcm_token = FcmToken.find_by(token: fcm_token_string_1)
    assert_not_equal fcm_token, nil
    assert_equal fcm_token.token, fcm_token_string_1
    assert_equal fcm_token.user_id, user_2.id
  end

  test 'should create dwolla account' do
    # Requires auth
    post 'me/dwolla'
    assert_response :unauthorized

    # Requires ssn and phone
    post 'me/dwolla', headers: @headers
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['ssn'], ['is required']

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
    post 'me/dwolla', headers: @headers, params: { ssn: '123-45-6789' }
    assert_response :bad_request
    res = JSON.parse(@response.body)
    assert_equal res['address'], ['is required']

    # Address in payload
    post 'me/dwolla', headers: @headers, params: {
      address: address,
      ssn: '123-45-6789'
    }
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
    # TODO Fake transactions
    post 'me/dev_refresh_transactions'
    assert_response :unauthorized

    assert_equal @user.transactions.size, 0
    get 'me/account_connect', headers: @headers, params: {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'wells'
    }
    assert_response :success
    @user.reload
    assert_not_equal @user.accounts.size, 0 # Has at least one bank account now

    # Get transactions without vices
    vices = %w(None)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    # TODO Fake transactions
    post 'me/dev_refresh_transactions', headers: @headers
    assert_response :success
    @user.reload
    assert_equal @user.transactions.size, 0

    # Get transactions with vice
    vices = %w(CoffeeShops)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    # TODO Fake transactions
    post 'me/dev_refresh_transactions', headers: @headers
    assert_response :success
    @user.reload
    assert_operator @user.transactions.size, :>, 0
  end

  test 'should populate dev' do
    # Not implemented
  end

  test 'should deduct into funds dev' do
    # Requires auth
    post 'me/dev_deduct'
    assert_response :unauthorized

    # Auth with Dwolla to test movement of money
    post 'me/dwolla', headers: @headers, params: { ssn: '123-45-6789' }
    assert_response :ok

    # Get transactions
    assert_equal @user.transactions.size, 0
    get 'me/account_connect', headers: @headers, params: {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'wells' # No MFA
    }
    assert_response :success
    @user.reload
    account_0 = @user.accounts.find_by(name: 'Plaid Savings')
    assert_not_equal account_0, nil
    account_1 = @user.accounts.find_by(name: 'Plaid Checking')
    assert_not_equal account_1, nil
    # Auth source/deposit Accounts with Dwolla
    put 'me/accounts', headers: @headers, params: {
      source: account_0.id,
      deposit: account_1.id
    }
    assert_response :success
    account_0.reload
    account_1.reload
    # Ensure both accounts were authed with Dwolla
    assert_not_equal account_0.dwolla_id, nil
    assert_not_equal account_1.dwolla_id, nil
    vices = %w(CoffeeShops)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    # TODO Fake transactions
    post 'me/dev_refresh_transactions', headers: @headers
    assert_response :success
    @user.reload
    # Make sure we've got a couple transactions to play with
    assert_operator @user.transactions.size, :>=, 2

    # Back out of one transaction
    backed_out_tx = @user.transactions[0]
    backed_out_tx.backed_out = true
    backed_out_tx.save!

    # Beef up amount so we meet Dwolla $1 transfer threshold
    @user.transactions.each do |tx|
      tx.amount += 10.0
      tx.save!
    end

    # Deduct
    assert_equal @user.fund.amount_invested, 0
    assert_equal @user.yearly_fund().amount_invested, 0
    post 'me/dev_deduct', headers: @headers
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

    # Testing Dwolla:
    # assert_equal DwollaTransaction.all.count, 1
    # dwolla_tx = DwollaTransaction.all.first
    #
    # # Switch to the Webhook controller to fake a webhook
    # old_controller = @controller
    # @controller = WebhooksController.new
    # post :dwolla, topic: 'customer_bank_transfer_completed',
    #               resourceId: dwolla_tx.dwolla_id
    # assert_response :success
    # # Restore the original controller
    # @controller = old_controller
  end

  test 'should aggregate funds dev' do
    # Requires auth
    post 'me/dev_aggregate'
    assert_response :unauthorized

    # Auth with Dwolla to test movement of money
    post 'me/dwolla', headers: @headers, params: { ssn: '123-45-6789' }
    assert_response :ok
    # Get transactions
    assert_equal @user.transactions.size, 0
    get 'me/account_connect', headers: @headers, params: {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'wells' # No MFA
    }
    assert_response :success
    @user.reload
    # Has checking/savings now
    checking = @user.accounts.find_by(account_subtype: 'checking')
    assert_not_equal checking, nil
    savings = @user.accounts.find_by(account_subtype: 'savings')
    assert_not_equal savings, nil
    # Auth source/deposit Accounts with Dwolla
    put 'me/accounts', headers: @headers, params: {
      source: checking.id,
      deposit: savings.id
    }
    assert_response :success
    vices = %w(CoffeeShops)
    put 'me/vices', headers: @headers, params: { vices: vices }
    assert_response :success
    # TODO Fake transactions
    post 'me/dev_refresh_transactions', headers: @headers
    assert_response :success
    @user.reload
    # Make sure we've got a couple transactions to play with
    assert_operator @user.transactions.size, :>=, 2

    # Deduct
    assert_equal @user.fund.amount_invested, 0.00
    assert_equal @user.yearly_fund().amount_invested, 0.00
    now = Date.current
    @user.transactions.each do |tx|
      # Force date to be today to avoid accidentally being aggregated
      tx.date = now
      # Beef up amount so we meet Dwolla $1 transfer threshold
      tx.amount += 10.0
      tx.save!
    end
    post 'me/dev_deduct', headers: @headers
    assert_response :success

    # Verify deduction
    @user.reload
    amount = 0.00 # Keep track of total amount invested
    last_month = Date.current.beginning_of_month - 1.month
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

    # Aggregate
    assert_equal @user.agexes.size, 0
    post 'me/dev_aggregate', headers: @headers
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
