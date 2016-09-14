class Api::V1::UsersController < ApplicationController
  include UserHelper
  include DwollaHelper
  include NotificationHelper
  before_action :init
  before_action :restrict_access, except: [:create]

  # POST /users
  def create
    # Create new User
    user = User.new(user_params)
    # Generate the User's auth token
    user.generate_token
    # Create the User's fund
    user.create_fund
    # Save and check for validation errors
    if user.save
      # Send User model with token
      return render json: user.with_token, status: :ok
    end
    render json: user.errors, status: :unprocessable_entity
  end

  # GET /users/me
  def get_me
    render json: @authed_user, status: :ok
  end

  # PATCH/PUT /users/me
  def update_me
    if @authed_user.update(user_update_params)
      return render json: @authed_user, status: :ok
    end
    render json: @authed_user.errors, status: :unprocessable_entity
  end

  # GET /users/me/yearly_fund
  def get_yearly_fund
    render json: @authed_user.yearly_fund(), status: :ok
  end

  # PUT /users/me/vices
  def set_vices
    vices = []
    unless params[:vices]
      errors = { vices: ['are nil'] }
      return render json: errors, status: :bad_request
    end
    unless params[:vices].is_a?(Array)
      errors = { vices: ['are in incorrect format'] }
      return render json: errors, status: :bad_request
    end
    params[:vices].each do |vice_name|
      if vice_name == 'None'
        @authed_user.vices.clear
        return render json: @authed_user, status: :ok
      end
      vice = Vice.find_by(name: vice_name)
      unless vice
        errors = { vices: ['have one or more invalid names'] }
        return render json: errors, status: :unprocessable_entity
      end
      vices.push vice
    end
    @authed_user.vices.clear
    @authed_user.vices << vices
    render json: @authed_user, status: :ok
  end

  def set_address
    addr = @authed_user.address
    addr = Address.new unless addr
    if addr.update(address_params)
      @authed_user.address = addr
      @authed_user.save!
      return render json: @authed_user, status: :ok
    end
    render json: addr.errors, status: :unprocessable_entity
  end

  # GET users/me/account_connect
  def account_connect
    unless params[:username]
      errors = { username: ['is required'] }
      return render json: errors, status: :bad_request
    end
    unless params[:password]
      errors = { password: ['is required'] }
      return render json: errors, status: :bad_request
    end
    unless params[:type]
      errors = { type: ['is required'] }
      return render json: errors, status: :bad_request
    end
    # Get Plaid user
    begin
      plaid_user = if params[:type] == 'bofa' || params[:type] == 'chase'
                     Plaid::User.create(:connect,
                                        params[:type],
                                        params[:username],
                                        params[:password],
                                        options: {
                                          login_only: true,
                                          webhook: 'https://app.dimention.co/api/v1/plaid_callback',
                                          list: true
                                        })
                   elsif params[:type] == 'usaa' && params[:pin]
                     Plaid::User.create(:connect,
                                        params[:type],
                                        params[:username],
                                        params[:password],
                                        pin: params[:pin],
                                        options: {
                                          login_only: true,
                                          webhook: 'https://app.dimention.co/api/v1/plaid_callback'
                                        })
                   else
                     Plaid::User.create(:connect,
                                        params[:type],
                                        params[:username],
                                        params[:password],
                                        options: {
                                          login_only: true,
                                          webhook: 'https://app.dimention.co/api/v1/plaid_callback'
                                        })
                   end
    rescue Plaid::PlaidError => e
      return handle_plaid_error(e)
    end

    set_bank(@authed_user, params[:type], plaid_user.access_token)

    render_mfa_or_populate(@authed_user, plaid_user)
  end

  # GET users/me/account_mfa
  def account_mfa
    unless params[:access_token]
      errors = { access_token: ['is required'] }
      return render json: errors, status: :bad_request
    end

    begin
      plaid_user = Plaid::User.load(:connect, params[:access_token])
      if !params[:answer].blank?
        plaid_user.mfa_step(params[:answer], options: {
          login_only: true,
          webhook: 'https://app.dimention.co/api/v1/plaid_callback'
        })
      elsif !params[:mask].blank?
        plaid_user.mfa_step(send_method: { mask: params[:mask] })
      elsif !params[:type].blank?
        plaid_user.mfa_step(send_method: { type: params[:type] })
      else
        errors = {
          answer: ['is required (unless selecting MFA method)'],
          mask: ['can be submitted instead of answer to select MFA method'],
          type: ['can be submitted instead of answer to select MFA method']
        }
        return render json: errors, status: :bad_request
      end
    rescue Plaid::PlaidError => e
      return handle_plaid_error(e)
    end
    render_mfa_or_populate(@authed_user, plaid_user)
  end

  # PUT users/me/accounts
  def update_accounts
    # Validate client input and look up Account models
    source_account, deposit_account, e1 =
      validate_deduction_accounts_payload(params[:source], params[:deposit])
    tracking_accounts, e2 =
      validate_tracking_accounts_payload(params[:tracking])
    errors = e1.merge(e2) { |k, o, n| o + n } # Key, old, new
    if source_account.nil? && deposit_account.nil? && tracking_accounts.blank?
      errors[:general] = ['Missing parameter. Options are one or more of: "source", "deposit", "tracking"']
    end
    unless errors.blank?
      return render json: errors, status: :bad_request
    end

    # Set Source/Deposit Accounts
    if source_account || deposit_account
      if @authed_user.dwolla_id
        if source_account
          if source_account.account_subtype != 'savings' &&
             source_account.account_subtype != 'checking'

            errors[:source] = ['must be of type "savings" or "checking"']
          else
            @authed_user.source_account = source_account
          end
        end
        if deposit_account
          if deposit_account.account_subtype != 'savings' &&
             deposit_account.account_subtype != 'checking'

            errors[:deposit] = ['must be of type "savings" or "checking"']
          else
            @authed_user.deposit_account = deposit_account
          end
        end
      else
        errors[:general] = ['User is not yet verified with Dwolla']
      end
      unless errors.blank?
        return render json: errors, status: :bad_request
      end
      @authed_user.save!
      @authed_user.dwolla_add_funding_sources
    end

    # Set Tracking Accounts
    tracking_accounts.each do |account|
      account.tracking = true
      account.save!
    end if tracking_accounts

    @authed_user.reload
    render json: @authed_user, status: :ok
  end

  # DELETE users/me/accounts
  def remove_accounts
    # Validate client input and look up Account models
    tracking_accounts, errors =
      validate_tracking_accounts_payload(params[:tracking])
    if !params.has_key?(:source) && !params.has_key?(:deposit) &&
      tracking_accounts.blank?

      errors[:general] = ['Missing parameter. Options are one or more of: "source", "deposit", "tracking"']
    end
    unless errors.blank?
      return render json: errors, status: :bad_request
    end

    # Remove Source/Deposit Accounts
    if params.has_key?(:source) || params.has_key?(:deposit)
      if params.has_key?(:source)
        @authed_user.source_account = nil
      end
      if params.has_key?(:deposit)
        @authed_user.deposit_account = nil
      end
      @authed_user.save!
    end
    # Remove funding sources that are no longer identified as source/deposit
    @authed_user.dwolla_remove_funding_sources

    # Remove Tracking Accounts
    tracking_accounts.each do |account|
      account.tracking = false
      account.save!
    end if tracking_accounts

    render json: @authed_user, status: :ok
  end

  def refresh_transactions
    @authed_user.refresh_transactions(true)
    @authed_user.reload
    render json: @authed_user, status: :ok
  end

  def register_push_token
    unless params[:token]
      errors = { token: ['is required'] }
      return render json: errors, status: :bad_request
    end
    if register_token_fcm(@authed_user, params[:token])
      return render json: { 'status' => 'registered' }, status: :ok
    end
    render json: { 'status' => 'failed to register' },
      status: :internal_server_error
  end

  def dwolla
    # Validate payload
    errors = {}
    unless params[:ssn]
      errors[:ssn] = ['is required']
    end
    addr = @authed_user.address
    unless addr
      if params[:address]
        addr = Address.new
      else
        errors[:address] = ['is required']
      end
    end
    unless errors.blank?
      return render json: errors, status: :bad_request
    end
    if params[:address]
      unless addr.update(address_params)
        return render json: addr.errors, status: :unprocessable_entity
      end
    end

    # Set User's Address used in User.dwolla_create
    @authed_user.address = addr
    @authed_user.save!

    if @authed_user.dwolla_create(params[:ssn], request.remote_ip)
      return head status: :ok
    end
    head status: :internal_server_error
  end

  def support
    # Validate payload
    unless params[:text]
      errors = { text: ['is required'] }
      return render json: errors, status: :bad_request
    end
    unless params[:text].length <= 1000
      errors = { text: ['must be 1000 characters or less'] }
      return render json: errors, status: :bad_request
    end

    # Build text
    text = '```' + params[:text] + '```' + "\n"
    text += 'FROM: ' + @authed_user.email

    # Build HTTPS request
    slack_key = ENV['SLACK_ROUTE']
    url = URI.parse('https://hooks.slack.com/services/' + slack_key)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(url.to_s)
    req['Content-Type'] = 'application/json'
    req.body = {
      'text' => text
    }.to_json

    # Send Slack message
    res = http.request(req)

    # TODO: Process response
    logger.info res

    head status: :ok
  end

  def dev_refresh_transactions
    # The method argument lets us take in older transactions for testing
    # purposes.
    @authed_user.refresh_transactions(false)
    @authed_user.reload
    render json: @authed_user, status: :ok
  end

  def dev_populate
    @authed_user.vices.destroy_all
    @authed_user.banks.destroy_all
    @authed_user.accounts.destroy_all
    @authed_user.transactions.destroy_all

    vices = []
    vice_coffeeshops = Vice.find_by(name: "CoffeeShops")
    vices.push vice_coffeeshops
    vice_electronics = Vice.find_by(name: "Electronics")
    vices.push vice_electronics
    @authed_user.vices << vices

    bank = @authed_user.banks.new(name: 'wells', access_token: 'test_wells')
    bank.save!

    account_savings = @authed_user.accounts.new(
      plaid_id: 'QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK',
      name: 'Plaid Savings',
      institution: 'fake_institution',
      account_num: '9900009606',
      routing_num: '021000021',
      account_type: 'depository',
      account_subtype: 'savings')
    account_savings.bank = bank
    account_savings.save!
    account_checking = @authed_user.accounts.new(
      plaid_id: 'nban4wnPKEtnmEpaKzbYFYQvA7D7pnCaeDBMy',
      name: 'Plaid Checking',
      institution: 'fake_institution',
      account_num: '1234567890',
      routing_num: '222222226',
      account_type: 'depository',
      account_subtype: 'checking')
    account_checking.bank = bank
    account_checking.save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'foo',
      date: DateTime.current,
      amount: 13.37,
      name: 'Python Sticker',
      category_id: '19013000')
    transaction.account = account_savings
    transaction.vice = vice_electronics
    transaction.save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'bar',
      date: DateTime.current-2.days,
      amount: 710.51,
      name: 'Microsoft Store',
      category_id: '19013000')
    transaction.account = account_savings
    transaction.vice = vice_electronics
    transaction.save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'KdDjmojBERUKx3JkDdO5IaRJdZeZKNuK4bnKJ1',
      date: DateTime.current-4.days,
      amount: 2307.15,
      name: 'Apple Store',
      category_id: '19013000')
    transaction.account = account_savings
    transaction.vice = vice_electronics
    transaction.backed_out = true
    transaction.save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'DAE3Yo3wXgskjXV1JqBDIrDBVvjMLDCQ4rMQdR',
      date: DateTime.current-7.days,
      amount: 4.19,
      name: 'Gregorys Coffee',
      category_id: '13005043')
    transaction.account = account_checking
    transaction.vice = vice_coffeeshops
    transaction.save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'moPE4dE1yMHJX5pmRzwrcvpQqPdDnZHEKPREYL',
      date: DateTime.current-8.days,
      amount: 7.23,
      name: 'Krankies Coffee',
      category_id: '13005043')
    transaction.account = account_savings
    transaction.vice = vice_coffeeshops
    transaction.backed_out = true
    transaction.save!

    amount = 5.32
    transaction = @authed_user.transactions.new(
      plaid_id: 'JmN0JX0q5EcaQJM9ZbOwUYyyp607m4u3PR63Vn',
      date: DateTime.current-13.days,
      amount: amount,
      name: 'Octane Coffee Bar and Lounge',
      category_id: '13005043')
    transaction.account = account_savings
    transaction.vice = vice_coffeeshops
    amount = amount * @authed_user.invest_percent / 100.0
    amount = amount.round(2)
    # Essentially reset funds
    @authed_user.fund.amount_invested = amount
    yearly_fund = @authed_user.yearly_fund()
    yearly_fund.amount_invested = amount
    # Gained a dollar of 'interest'
    @authed_user.fund.balance = amount + 1.00
    @authed_user.fund.save!
    yearly_fund.balance = amount + 1.00
    yearly_fund.save!
    transaction.invest!(amount) # Calls Transaction#save!

    transaction = @authed_user.transactions.new(
      plaid_id: 'baz',
      date: DateTime.current-15.days,
      amount: 6.78,
      name: 'Moar Electronics',
      category_id: '13005043')
    transaction.account = account_savings
    transaction.vice = vice_electronics
    transaction.save!

    render json: @authed_user, status: :ok
  end

  def dev_deduct
    current_month = Date.current.beginning_of_month

    # Step 1: Go through every Transaction and get a list of all
    # Transactions that are to be invested, as well as the total dollar
    # amount to be invested this week. At the same time, aggregate all old
    # Transactions into Agexes.
    amount_to_invest = 0.0
    transactions_to_invest = []
    @authed_user.transactions.each do |transaction|

      if transaction.archived
        # Re-archive in order to delete the Transaction if it is too old
        transaction.archive!
        next
      end

      # Archive backed_out Transactions
      if transaction.backed_out
        transaction.archive!
        next
      end

      # Deduct Transactions
      unless transaction.invested
        amount = transaction.amount * @authed_user.invest_percent / 100.0
        amount = amount.round(2)
        amount_to_invest += amount
        transactions_to_invest.push transaction
      end

      # Don't aggregate/delete if Transaction is still of current month
      month = transaction.date.beginning_of_month
      next unless month < current_month

      # Aggregate old Transactions
      agexes = @authed_user.agexes.where(month: month)
      agex = agexes.find_by(vice_id: transaction.vice.id)
      unless agex
        agex = @authed_user.agexes.new
        agex.vice = transaction.vice
        agex.month = month
      end
      agex.amount += transaction.amount_invested
      agex.save!

      # Archive all old Transactions, even if they're included in
      # transactions_to_invest.
      transaction.archive!
    end

    # Step 2: Deduct the total amount from the User's source Account into
    # their Deposit account. If they do not have source/deposit Accounts
    # specified or set up with Dwolla, this call will do nothing.
    @authed_user.dwolla_transfer(amount_to_invest)

    # Step 3: Mark all Transactions in transactions_to_invest as 'invested'.
    # Note, we won't check whether or not they are archived here because
    # they may have been archived by Step 1. We still want to modify their
    # 'invested' state. Step 1 will check if the Transaction was archived
    # before placing it in the transactions_to_invest array.
    transactions_to_invest.each do |transaction|
      amount = transaction.amount * @authed_user.invest_percent / 100.0
      amount = amount.round(2)
      transaction.invest!(amount)
    end

    render json: @authed_user, status: :ok
  end

  def dev_aggregate
    current_month = Date.current.beginning_of_month
    # current_month -= 21.months # Dev
    @authed_user.transactions.each do |transaction|
      month = transaction.date.beginning_of_month
      # month = current_month - 1.month # Dev
      next unless month < current_month
      if transaction.invested
        agexes = @authed_user.agexes.where(month: month)
        agex = agexes.find_by(vice_id: transaction.vice.id)
        unless agex
          agex = @authed_user.agexes.new
          agex.vice = transaction.vice
          agex.month = month
        end
        agex.amount += transaction.amount_invested
        agex.save!
      end
      # Archive all old transactions, even if they haven't been invested
      transaction.archive!
      @authed_user.reload
    end
    render json: @authed_user, status: :ok
  end

  def dev_notify
    # Validate payload
    errors = {}
    unless params[:title]
      errors[:title] = ['is required']
    end
    unless params[:body]
      errors[:body] = ['is required']
    end
    unless errors.blank?
      return render json: errors, status: :bad_request
    end
    unless test_notification(@authed_user, params[:title], params[:body])
      return head status: :internal_server_error
    end
    render json: { 'notification' => 'sent' }, status: :ok
  end

  def dev_email
    # UserMailer.welcome_email(@authed_user).deliver_later
    UserMailer.welcome_email(@authed_user).deliver_now
    head status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :password, :phone, :dob,
                                 :email, :invest_percent, :goal)
  end

  def user_update_params
    # No :email or :dob
    params.require(:user).permit(:fname, :lname, :password, :phone,
                                 :invest_percent, :goal)
  end

  def address_params
    params.require(:address).permit(:line1, :line2, :city, :state, :zip)
  end

  def validate_deduction_accounts_payload(source, deposit)
    errors = {}
    if !source.nil?
      if source.is_a?(String)
        source_account = Account.find_by(id: source)
        if source_account.nil?
          errors[:source] = ['Account not found']
        end
      else
        errors[:source] = ['is incorrectly formatted - must be of type String']
      end
    end
    if !deposit.nil?
      if deposit.is_a?(String)
        deposit_account = Account.find_by(id: deposit)
        if deposit_account.nil?
          errors[:deposit] = ['Account not found']
        end
      else
        errors[:deposit] = ['is incorrectly formatted - must be of type String']
      end
    end
    return source_account, deposit_account, errors
  end

  def validate_tracking_accounts_payload(tracking)
    errors = {}
    if !tracking.nil?
      if tracking.is_a?(Array)
        tracking_accounts = []
        tracking.each do |tracking_account_id|
          tracking_account = Account.find_by(id: tracking_account_id)
          if tracking_account.nil?
            errors[:tracking] = ['Account not found']
          else
            tracking_accounts.push(tracking_account)
          end
        end
      else
        errors[:tracking] = ['is incorrectly formatted - must be of type Array']
      end
    end
    return tracking_accounts, errors
  end

end
