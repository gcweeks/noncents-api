class Api::V1::UsersController < ApplicationController
  include UserHelper
  include ViceParser
  before_action :init
  before_action :restrict_access, except: [:create]

  # POST /users
  def create
    # Create new User
    user = User.new(user_params)
    user.generate_token!
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
    if @authed_user.update!(user_update_params)
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

  def dev_transactions
    transactions = []
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
      plaid_user.transactions.each do |transaction|
        accounts = @authed_user.accounts.map(&:plaid_id)
        next unless accounts.include? transaction.account
        vice = get_vice(transaction.category[0],
                        transaction.category[1],
                        transaction.category[2])
        # TODO: Should this be vice or vice.id?
        next unless @authed_user.vices.map(&:id).include? vice.id
        model = Transaction.create_from_plaid(transaction)
        model.vice = vice.id # TODO: Should this be vice or vice.id?
        model.save!
        transactions.push model
      end if plaid_user.transactions
    end
    render json: transactions, status: :ok
  end

  def dev_deduct
    @authed_user.transactions.each do |transaction|
      next if transaction.deducted
      amount = transaction.amount * @authed_user.invest_percent / 100.0
      amount = amount.round(2)
      @authed_user.fund.deposit amount
    end
  end

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :password, :number, :dob,
                                 :email, :invest_percent)
  end

  def user_update_params
    # No :email
    params.require(:user).permit(:fname, :lname, :password, :number, :dob,
                                 :invest_percent)
  end
end
