class Api::V1::UsersController < ApplicationController
  include UserHelper
  include DwollaHelper
  include NotificationHelper
  include ViceParser
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
      user.dwolla_create # TODO: Check for success
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

    set_bank params[:type], plaid_user.access_token

    if plaid_user.mfa?
      # MFA
      ret = plaid_user.instance_values.slice 'access_token', 'mfa_type', 'mfa'
      return render json: ret, status: :ok
    end

    ret = populate_user_accounts @authed_user, plaid_user
    # 'ret' will either be a successfully saved User model or an ActiveRecord
    # error hash.
    unless ret.is_a? User
      return render json: ret, status: :internal_server_error
    end
    return render json: ret, status: :ok
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

    if plaid_user.mfa?
      # More MFA
      ret = plaid_user.instance_values.slice 'access_token', 'mfa_type', 'mfa'
      return render json: ret, status: :ok
    end

    ret = populate_user_accounts @authed_user, plaid_user
    # 'ret' will either be a successfully saved User model or an ActiveRecord
    # error hash.
    unless ret.is_a? User
      return render json: ret, status: :internal_server_error
    end
    return render json: ret, status: :ok
  end

  # PUT users/me/remove_accounts
  def remove_accounts
    unless params[:accounts]
      errors = { accounts: ['are required'] }
      return render json: errors, status: :bad_request
    end
    unless params[:accounts].is_a?(Array)
      errors = { accounts: ['are in incorrect format'] }
      return render json: errors, status: :bad_request
    end
    account_array = []
    params[:accounts].each do |account_id|
      account = Account.find_by(id: account_id)
      return head :not_found unless account
      unless @authed_user.accounts.map(&:id).include? account.id
        return head :unauthorized
      end
      account_array.push account
    end
    account_array.each(&:destroy)
    # Refresh User
    @authed_user = User.find_by(id: @authed_user.id)
    # Add remaining accounts to Dwolla
    @authed_user.dwolla_add_funding_source
    render json: @authed_user, status: :ok
  end

  def refresh_transactions
    perform_refresh_transactions(true)
  end

  def dev_refresh_transactions
    # The method argument lets us take in older transactions for testing
    # purposes.
    perform_refresh_transactions(false)
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
      account_num: 0,
      routing_num: 0,
      account_type: 'depository',
      account_subtype: 'savings')
    account_savings.save!
    account_checking = @authed_user.accounts.new(
      plaid_id: 'nban4wnPKEtnmEpaKzbYFYQvA7D7pnCaeDBMy',
      name: 'Plaid Checking',
      institution: 'fake_institution',
      account_num: 0,
      routing_num: 0,
      account_type: 'depository',
      account_subtype: 'checking')
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
    @authed_user.transactions.each do |transaction|
      next if transaction.invested
      if transaction.backed_out
        transaction.destroy
        next
      end
      amount = transaction.amount * @authed_user.invest_percent / 100.0
      amount = amount.round(2)
      # A bit confusing: in this context, 'Fund.transaction' refers to the
      # fact that an all-or-nothing database operation ('transaction') is
      # taking place, not to the identically-named Transaction model.
      Fund.transaction do
        @authed_user.fund.deposit!(amount)
        @authed_user.yearly_fund().deposit!(amount)
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
        agex = agexes.where(vice_id: transaction.vice.id).first
        unless agex
          agex = @authed_user.agexes.new
          agex.vice = transaction.vice
          agex.month = month
        end
        agex.amount += transaction.amount_invested
        agex.save!
      end
      # Destroy all old transactions, even if they haven't been invested
      transaction.destroy
      @authed_user.reload
    end
    render json: @authed_user, status: :ok
  end

  def dev_notify
    test_notification(@authed_user)
    render json: { 'notification' => 'sent' }, status: :ok
  end

  private

  def perform_refresh_transactions(ignore_old)
    # Get transactions for each bank
    @authed_user.banks.each do |bank|
      # Get Plaid model
      begin
        plaid_user = Plaid::User.load(:connect, bank.access_token)
        transactions = plaid_user.transactions
      rescue Plaid::PlaidError => e
        handle_plaid_error(e)
      end
      # Push transaction if it is from an account that the user has added and
      # matches one of the user's vices.
      transactions.each do |plaid_transaction|
        # Skip transactions without categories, because it means we can't
        # associate it with a Vice anyway.
        next unless plaid_transaction.category_hierarchy
        # Skip transactions with negative amounts
        next unless plaid_transaction.amount > 0.0
        # Skip transactions created more than 2 weeks ago
        next if ignore_old && plaid_transaction.date < Date.current - 2.weeks
        # Skip transactions that the user already has
        transaction_ids = @authed_user.transactions.map(&:plaid_id)
        next if transaction_ids.include? plaid_transaction.id
        # Skip transactions for accounts that the user has not told us to track
        account_ids = @authed_user.accounts.map(&:plaid_id)
        next unless account_ids.include? plaid_transaction.account_id
        # Get Vice model via category, subcategory, and sub-subcategory
        vice = get_vice(plaid_transaction.category_hierarchy[0],
                        plaid_transaction.category_hierarchy[1],
                        plaid_transaction.category_hierarchy[2])
        # Skip all transactions that aren't classified as a particular vice
        next if vice.nil?
        next unless @authed_user.vices.include? vice
        # Create Transaction
        transaction = Transaction.from_plaid(plaid_transaction)
        account = Account.find_by(plaid_id: plaid_transaction.account_id)
        transaction.account = account
        transaction.vice = vice
        transaction.save!
        @authed_user.transactions << transaction
      end if plaid_user.transactions
    end
    @authed_user.sync_date = DateTime.current
    @authed_user.save!
    render json: @authed_user, status: :ok
  end

  def user_params
    params.require(:user).permit(:fname, :lname, :password, :number, :dob,
                                 :email, :invest_percent, :goal)
  end

  def user_update_params
    # No :email or :dob
    params.require(:user).permit(:fname, :lname, :password, :number,
                                 :invest_percent, :goal)
  end

  def address_params
    params.require(:address).permit(:line1, :line2, :city, :state, :zip)
  end

  def handle_plaid_error(e)
    status = case e
    when Plaid::BadRequestError
      :bad_request
    when Plaid::UnauthorizedError
      :unauthorized
    when Plaid::RequestFailedError
      :payment_required
    when Plaid::NotFoundError
      :not_found
    when Plaid::ServerError
      :internal_server_error
    else
      :internal_server_error
    end
    render json: {
      'code' => e.code,
      'message' => e.message,
      'resolve' => e.resolve
    }, status: status
  end
end
