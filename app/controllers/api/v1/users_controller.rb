class Api::V1::UsersController < ApplicationController
  include UserHelper
  include DwollaHelper
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
      logger.info @authed_user.password
      return render json: @authed_user, status: :ok
    end
    render json: @authed_user.errors, status: :unprocessable_entity
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
                     Plaid.add_user('connect',
                                    params[:username],
                                    params[:password],
                                    params[:type],
                                    nil,
                                    list: true)
                   elsif params[:type] == 'usaa' && params[:pin]
                     Plaid.add_user('connect',
                                    params[:username],
                                    params[:password],
                                    params[:type],
                                    params[:pin])
                   else
                     Plaid.add_user('connect',
                                    params[:username],
                                    params[:password],
                                    params[:type])
                   end
    rescue Plaid::PlaidError => e
      return render json: {
        'code' => e.code,
        'message' => e.message,
        'resolve' => e.resolve
      }, status: :unauthorized
    end
    set_bank params[:type], plaid_user.access_token
    if plaid_user.api_res == 'success'
      ret = populate_user_accounts @authed_user, plaid_user
      # ret will either be a successfully saved User model or an error hash
      unless ret.is_a? User
        return render json: ret, status: :internal_server_error
      end
      return render json: ret, status: :ok
    end
    # MFA
    render json: plaid_user, status: :ok
  end

  # GET users/me/account_mfa
  def account_mfa
    unless params[:access_token]
      errors = { access_token: ['is required'] }
      return render json: errors, status: :bad_request
    end

    begin
      plaid_user = Plaid.set_user(params[:access_token], ['connect'])
      if params[:mask]
        plaid_user.select_mfa_method(mask: params[:mask])
        return head :ok
      elsif params[:type]
        plaid_user.select_mfa_method(type: params[:type])
        return head :ok
      elsif params[:answer]
        plaid_user.mfa_authentication(params[:answer])
      else
        errors = {
          answer: ['is required (unless selecting MFA method)'],
          mask: ['can be submitted instead of answer to select MFA method'],
          type: ['can be submitted instead of answer to select MFA method']
        }
        return render json: errors, status: :bad_request
      end
    rescue Plaid::PlaidError => e
      return render json: {
        'code' => e.code,
        'message' => e.message,
        'resolve' => e.resolve
      }, status: :unauthorized
    end
    if plaid_user.api_res == 'success'
      ret = populate_user_accounts @authed_user, plaid_user
      # ret will either be a successfully saved User model or an error hash
      unless ret.is_a? User
        return render json: ret, status: :internal_server_error
      end
      return render json: ret, status: :ok
    end
    # More MFA
    render json: plaid_user, status: :ok
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
    render json: @authed_user, status: :ok
  end

  def refresh_transactions
    # Get transactions for each bank
    @authed_user.banks.each do |bank|
      # Get Plaid model
      begin
        plaid_user = Plaid.set_user(bank.access_token, ['connect'])
      rescue Plaid::PlaidError => e
        return render json: {
          'code' => e.code,
          'message' => e.message,
          'resolve' => e.resolve
        }, status: :unauthorized
      end
      # Push transaction if it is from an account that the user has added and
      # matches one of the user's vices.
      plaid_user.transactions.each do |plaid_transaction|
        # Skip transactions without categories, because it means we can't
        # associate it with a Vice anyway.
        next unless plaid_transaction.category
        # Skip transactions with negative amounts
        next unless plaid_transaction.amount > 0.0
        # Skip transactions that the user already has
        transaction_ids = @authed_user.transactions.map(&:plaid_id)
        next if transaction_ids.include? plaid_transaction.id
        # Skip transactions for accounts that the user has not told us to track
        account_ids = @authed_user.accounts.map(&:plaid_id)
        next unless account_ids.include? plaid_transaction.account
        # Get Vice model via category, subcategory, and sub-subcategory
        vice = get_vice(plaid_transaction.category[0],
                        plaid_transaction.category[1],
                        plaid_transaction.category[2])
        # Skip all transactions that aren't classified as a particular vice
        next if vice.nil?
        next unless @authed_user.vices.include? vice
        # Create Transaction
        transaction = Transaction.from_plaid(plaid_transaction)
        # Skip transactions created more than 2 weeks ago
        next unless transaction.date > Date.current - 2.weeks
        account = Account.find_by(plaid_id: plaid_transaction.account)
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

  def dev_deduct
    @authed_user.transactions.each do |transaction|
      next if transaction.invested || transaction.backed_out
      amount = transaction.amount * @authed_user.invest_percent / 100.0
      amount = amount.round(2)
      # Confusing here, but in this context, 'Fund.transaction' refers to the
      # fact that an all-or-nothing database operation is taking place, not to
      # the actual Transaction model.
      Fund.transaction do
        @authed_user.fund.deposit!(amount)
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
      transaction.destroy
      @authed_user.reload
    end
    render json: @authed_user, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :password, :number, :dob,
                                 :email, :invest_percent, :goal)
  end

  def user_update_params
    # No :email or :dob
    params.require(:user).permit(:fname, :lname, :password, :number,
                                 :invest_percent, :goal)
  end
end
