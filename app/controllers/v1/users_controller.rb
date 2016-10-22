class V1::UsersController < ApplicationController
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
    raise UnprocessableEntity.new(user.errors) unless user.save
    # Send User model with token
    render json: user.with_token, status: :ok
  end

  # GET /users/me
  def get_me
    render json: @authed_user, status: :ok
  end

  # PATCH/PUT /users/me
  def update_me
    unless @authed_user.update(user_update_params)
      raise UnprocessableEntity.new(@authed_user.errors)
    end
    render json: @authed_user, status: :ok
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
      raise BadRequest.new(errors)
    end
    unless params[:vices].is_a?(Array)
      errors = { vices: ['are in incorrect format'] }
      raise BadRequest.new(errors)
    end
    params[:vices].each do |vice_name|
      if vice_name == 'None'
        @authed_user.vices.clear
        return render json: @authed_user, status: :ok
      end
      vice = Vice.find_by(name: vice_name)
      unless vice
        errors = { vices: ['have one or more invalid names'] }
        raise UnprocessableEntity.new(errors)
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

  # POST users/me/plaid
  def plaid
    errors = {}
    errors[:username] = ['is required'] if params[:username].blank?
    errors[:password] = ['is required'] if params[:password].blank?
    if params[:product].blank?
      errors[:product] = ['is required']
    else
      products = %w(connect auth)
      unless products.include?(params[:product])
        errors[:product] = ['must be one of: ' + products.join(', ')]
      end
    end
    if params[:type].blank?
      errors[:type] = ['is required']
    else
      auth_types = %w(bbt bofa capone360 schwab chase citi fidelity nfcu pnc
                      suntrust td us usaa wells)
      connect_types = %w(amex bbt bofa chase citi nfcu suntrust td us usaa
                         wells)
      types = (params[:product] == 'auth') ? auth_types : connect_types
      unless types.include?(params[:type])
        errors[:type] = [
          params[:product]+ ' type must be one of: ' + types.join(', '),
          'cannot be ' + params[:type].to_s
        ]
      end
      if params[:type] == 'usaa'
        errors[:pin] = ['is required for usaa'] if params[:pin].blank?
      end
    end
    raise BadRequest.new(errors) if errors.present?

    product = params[:product].to_sym
    options = {}
    # 'login_only' gets only the credentials for a Plaid Connect user, omitting
    # the user's transactions.
    options[:login_only] = true if params[:product] == 'connect'
    # 'list' lists the available destinations an MFA Code can be sent
    options[:list] = true if params[:type] == 'chase'
    # USAA requires a pin for authentication
    pin = (params[:type] == 'usaa') ? params[:pin] : nil
    # Webhooks for transactions and account issues
    if ENV['RAILS_ENV'] == 'production'
      domain = ENV['DOMAIN']
      raise InternalServerError if domain.blank?
      options[:webhook] = 'https://' + domain + '/v1/webhooks/plaid'
    end

    # Create Plaid user
    begin
      plaid_user = Plaid::User.create(product,
                                      params[:type],
                                      params[:username],
                                      params[:password],
                                      pin: pin,
                                      options: options)
    rescue Plaid::PlaidError => e
      raise get_plaid_error(e)
    end

    ret = mfa_or_populate(@authed_user,
                          plaid_user,
                          params[:product],
                          params[:type])
    raise ret if ret.class <= Error
    render json: ret, status: :ok
  end

  # POST users/me/plaid_upgrade
  def plaid_upgrade
    errors = {}

    # Validate params
    errors[:product] = ['is required'] if params[:product].blank?
    if params[:account].blank?
      errors[:account] = ['is required']
    else
      account = Account.find_by(id: params[:account])
      errors[:account] = ['does not exist'] if account.nil?
    end
    raise BadRequest.new(errors) if errors.present?

    # Validate account
    if !account.bank.plaid_auth && !account.bank.plaid_connect
      errors[:account] = ['cannot be upgraded']
    end
    # Validate product
    if params[:product] == 'auth'
      if account.bank.plaid_auth
        (errors[:account] ||= []).push('already has Auth')
      end
    elsif params[:product] == 'connect'
      if account.bank.plaid_connect
        (errors[:account] ||= []).push('already has Connect')
      end
    else
      errors[:product] = ["must be one of: 'connect', 'auth'"]
    end
    raise BadRequest.new(errors) if errors.present?

    product = params[:product].to_sym
    # We can do this because we validated for already-upgraded Banks
    existing_product = account.bank.plaid_auth ? :auth : :connect
    begin
      existing_user = Plaid::User.load(existing_product, account.bank.access_token)
      new_user = existing_user.upgrade(product)
    rescue Plaid::PlaidError => e
      raise get_plaid_error(e)
    end

    ret = mfa_or_populate(@authed_user, new_user, params[:product])
    raise ret if ret.class <= Error
    render json: ret, status: :ok
  end

  # POST users/me/plaid_mfa
  def plaid_mfa
    errors = {}
    errors[:access_token] = ['is required'] if params[:access_token].blank?
    if params[:product].blank?
      errors[:product] = ['is required']
    else
      products = %w(connect auth)
      unless products.include?(params[:product])
        errors[:product] = ['must be one of: ' + products.join(', ')]
      end
    end
    if params[:answer].blank? && params[:mask].blank? && params[:type].blank?
      errors[:answer] = ['is required (unless selecting MFA method)']
      errors[:mask] = ['can be submitted instead of answer to select MFA method']
      errors[:type] = ['can be submitted instead of answer to select MFA method']
    end
    raise BadRequest.new(errors) if errors.present?

    product = params[:product].to_sym
    begin
      plaid_user = Plaid::User.load(product, params[:access_token])
    rescue Plaid::PlaidError => e
      raise get_plaid_error(e)
    end

    if params[:answer].present?
      options = {}
      # 'login_only' gets only the credentials for a Plaid Connect user,
      # omitting the user's transactions.
      options[:login_only] = true if params[:product] == 'connect'
      # Webhooks for transactions and account issues
      if ENV['RAILS_ENV'] == 'production'
        domain = ENV['DOMAIN']
        raise InternalServerError if domain.blank?
        options[:webhook] = 'https://' + domain + '/v1/webhooks/plaid'
      end

      begin
        plaid_user.mfa_step(params[:answer], options: options)
      rescue Plaid::PlaidError => e
        raise get_plaid_error(e)
      end
    else # Selecting send_method for MFA code
      method = if params[:mask].present?
                 { mask: params[:mask] }
               else # type
                 { type: params[:type] }
               end

      begin
        plaid_user.mfa_step(send_method: method, options: options)
      rescue Plaid::PlaidError => e
        raise get_plaid_error(e)
      end
    end

    ret = mfa_or_populate(@authed_user, plaid_user, params[:product])
    render json: ret, status: :ok
  end

  # PUT users/me/accounts
  def update_accounts
    # Validate client input and look up Account models
    source_account, deposit_account, e1 =
      validate_deduction_accounts_payload(params[:source], params[:deposit])
    tracking_accounts, e2 =
      validate_tracking_accounts_payload(params[:tracking])
    errors = e1.merge(e2) { |k, o, n| o + n } # Key, old, new
    if source_account.nil? && deposit_account.nil? && tracking_accounts.empty?
      errors[:general] = ["Missing parameter. Options are one or more of: 'source', 'deposit', 'tracking'"]
    end
    raise BadRequest.new(errors) if errors.present?

    # Validate/Set Source/Deposit Accounts
    if source_account || deposit_account
      if @authed_user.dwolla_id
        types = %w(savings checking)
        if source_account
          if types.exclude?(source_account.account_subtype)
            errors[:source] = ['type must be one of: ' + types.join(', ')]
          elsif !source_account.bank.plaid_auth
            errors[:source] = ['must have Plaid Auth product']
          else
            @authed_user.source_account = source_account
          end
        end
        if deposit_account
          if types.exclude?(deposit_account.account_subtype)
            errors[:deposit] = ['type must be one of: ' + types.join(', ')]
          elsif !deposit_account.bank.plaid_auth
            errors[:deposit] = ['must have Plaid Auth product']
          else
            @authed_user.deposit_account = deposit_account
          end
        end
      else
        errors[:general] = ['User is not yet verified with Dwolla']
      end
    end
    # Validate Tracking accounts
    tracking_accounts.each do |account|
      if !account.bank.plaid_connect
        (errors[:tracking] ||= []).push(
          'Account with ID ' + account.id + ' must have Plaid Connect product'
        )
      end
    end
    # Report errors with Tracking/Source/Deposit Accounts
    raise BadRequest.new(errors) if errors.present?

    # Save Source/Deposit Accounts
    if source_account || deposit_account
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
      tracking_accounts.empty?

      errors[:general] = ["Missing parameter. Options are one or more of: 'source', 'deposit', 'tracking'"]
    end
    raise BadRequest.new(errors) unless errors.blank?

    # Remove Source/Deposit Accounts
    if params.has_key?(:source) || params.has_key?(:deposit)
      if params.has_key?(:source)
        @authed_user.source_account = nil
      end
      if params.has_key?(:deposit)
        @authed_user.deposit_account = nil
      end
      @authed_user.save!
      # Remove funding sources that are no longer identified as source/deposit
      @authed_user.reload
      @authed_user.dwolla_remove_funding_sources
    end

    # Remove Tracking Accounts
    tracking_accounts.each do |account|
      account.tracking = false
      account.save!
    end if tracking_accounts

    render json: @authed_user, status: :ok
  end

  def dwolla
    # Validate payload, optionally including storing address
    errors = {}
    unless params[:ssn]
      errors[:ssn] = ['is required']
    end
    addr = @authed_user.address
    unless addr
      if params[:address].present?
        addr = Address.new(address_params)
        @authed_user.address = addr
      else
        errors[:address] = ['is required']
      end
    end
    raise BadRequest.new(errors) unless errors.blank?
    if params[:address]
      raise UnprocessableEntity.new(addr.errors) unless addr.save
    end
    @authed_user.save!

    # Whether to create or retry creation of a Dwolla Customer object
    retrying = params[:retry].present?
    # User's Address will be used in User.dwolla_create
    unless @authed_user.dwolla_create(params[:ssn], request.remote_ip, retrying)
      raise InternalServerError
    end

    @authed_user.reload
    render json: @authed_user, status: :ok
  end

  def dwolla_document
    # Validate payload
    errors = {}
    document_types = %w(passport license idCard)
    if params[:type].blank?
      errors[:type] = ['is required']
    elsif document_types.exclude?(params[:type])
      errors[:type] = ['must be one of: ' + document_types.join(', ')]
    end
    if params[:file].blank?
      errors[:file] = ['is required']
    elsif params[:file].class != ActionDispatch::Http::UploadedFile
      errors[:file] = ['is uploaded incorrectly']
    else
      filetypes = %w(.jpg .jpeg .png .tif .pdf)
      extension = params[:file].original_filename[/\.[A-Za-z]{3,4}$/]
      unless filetypes.include?(extension)
        errors[:file] = ['must be one of: ' + filetypes.join(', ')]
      end
    end
    raise BadRequest.new(errors) unless errors.blank?

    file = Faraday::UploadIO.new params[:file].path, params[:file].content_type
    unless @authed_user.dwolla_submit_document(file, params[:type])
      raise InternalServerError
    end

    @authed_user.reload
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
      raise BadRequest.new(errors)
    end
    unless register_token_fcm(@authed_user, params[:token])
      errors = { status: 'failed to register' }
      raise InternalServerError.new(errors)
    end
    render json: { status: 'registered' }, status: :ok
  end

  def support
    # Validate payload
    unless params[:text]
      errors = { text: ['is required'] }
      raise BadRequest.new(errors)
    end
    unless params[:text].length <= 1000
      errors = { text: ['must be 1000 characters or less'] }
      raise BadRequest.new(errors)
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

    head :ok
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
    @authed_user.deposit_account = account_savings
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
    @authed_user.source_account = account_checking
    @authed_user.save!
    @authed_user.dwolla_add_funding_sources

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

    # Dwolla only lets us make transactions of a dollar or more.
    if amount_to_invest > 1.00
      # Step 2: Deduct the total amount from the User's source Account into
      # their Deposit account. If they do not have source/deposit Accounts
      # specified or set up with Dwolla, this call will do nothing. For now,
      # we will ignore the return value of this method.
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
    raise BadRequest.new(errors) unless errors.blank?
    unless test_notification(@authed_user, params[:title], params[:body])
      raise InternalServerError
    end
    render json: { 'notification' => 'sent' }, status: :ok
  end

  def dev_email
    # UserMailer.welcome_email(@authed_user).deliver_now
    head :ok
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

  def plaid_login()
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

    # Tuples require 'return' keyword
    return source_account, deposit_account, errors
  end

  def validate_tracking_accounts_payload(tracking)
    errors = {}
    tracking_accounts = []
    if !tracking.nil?
      if tracking.is_a?(Array)
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

    # Tuples require 'return' keyword
    return tracking_accounts, errors
  end
end
