class V1::ApiController < ApplicationController
  include ApiHelper

  before_action :init
  before_action :restrict_access, except: [
    # List of route methods that do not need authentication
    :request_get,
    :request_post,
    :auth,
    :reset_password,
    :update_password,
    :signup,
    :check_email,
    :twilio_callback,
    :weekly_deduct_cron,
    :transaction_refresh_cron,
    :dev_ratelimit,
    :version_ios
  ]

  ##############################################################################
  # Calls that don't require access_token
  ##############################################################################
  def request_get
    render json: { 'body' => 'GET Request' }, status: :ok
  end

  def request_post
    render json: { 'body' => "POST Request: #{request.body.read}" }, status: :ok
  end

  def auth
    # Alternative to users_get call that returns the User token in addition to
    # the rest of the model, provided proper authentication is given.

    if params[:user].blank?
      errors = { email: ['cannot be blank'], password: ['cannot be blank'] }
      raise BadRequest.new(errors)
    end
    if params[:user][:email].blank?
      errors = { email: ['cannot be blank'] }
      raise BadRequest.new(errors)
    end
    if params[:user][:password].blank?
      errors = { password: ['cannot be blank'] }
      raise BadRequest.new(errors)
    end
    user = User.find_by(email: params[:user][:email])
    return head :not_found unless user
    # Log this authentication event
    ip_addr = IPAddr.new(request.remote_ip)
    auth_event = AuthEvent.new(ip_address: ip_addr)
    auth_event.user = user
    user = user.try(:authenticate, params[:user][:password])
    unless user
      auth_event.success = false
      auth_event.save!
      errors = { password: ['is incorrect'] }
      return render json: errors, status: :unauthorized
    end
    auth_event.success = true
    auth_event.save!
    if user.token.blank?
      # Generate access token for User
      user.generate_token
      # Save and check for validation errors
      raise UnprocessableEntity.new(user.errors) unless user.save
    end
    # Send User model with token
    render json: user.with_token, status: :ok
  end

  def reset_password
    unless params[:user] && params[:user][:email]
      errors = { email: 'is required' }
      raise BadRequest.new(errors) unless errors.blank?
    end

    user = User.find_by(email: params[:user][:email])
    return head :not_found unless user

    token = user.generate_password_reset
    user.save!
    UserMailer.password_reset(user, token).deliver_now
    head :ok
  end

  def update_password
    errors = {}
    if params[:user].blank?
      errors = {
        email: 'is required',
        password: 'is required'
      }
      raise BadRequest.new(errors)
    else
      errors[:email] = 'is required' if params[:user][:email].blank?
      errors[:password] = 'is required' if params[:user][:password].blank?
    end
    errors[:token] = 'is required' if params[:token].blank?
    raise BadRequest.new(errors) unless errors.blank?

    user = User.find_by(email: params[:user][:email])
    return head :not_found unless user

    unless user.reset_password_token && user.reset_password_sent_at
      errors = { token: 'has never been requested' }
      raise BadRequest.new(errors)
    end

    diff = DateTime.current - user.reset_password_sent_at.to_datetime
    # Difference between DateTimes is in days, convert to seconds
    diff *= 1.days
    unless diff.between?(0.seconds, 10.minutes)
      errors = { token: 'is expired' }
      return render json: errors, status: :bad_request
    end

    unless params[:token] == user.reset_password_token
      errors = { token: 'is incorrect' }
      return render json: errors, status: :bad_request
    end

    unless user.update(password: params[:user][:password])
      raise UnprocessableEntity.new(user.errors)
    end

    head :ok
  end

  def check_email
    user = User.find_by(email: params[:email])
    return render json: { 'email' => 'exists' }, status: :ok if user
    render json: { 'email' => 'does not exist' }, status: :ok
  end

  def weekly_deduct_cron
    raise NotFound unless request.remote_ip == '127.0.0.1'

    current_month = Date.current.beginning_of_month
    logger.info DateTime.current.strftime(
      "CRON: Start weekly_deduct_cron at %Y-%m-%d %H:%M:%S::%L %z")

    User.all.each do |user|
      logger.info 'CRON: Starting Transaction processing for ' + user.fname +
        ' ' + user.lname + ' (' + user.id.to_s + ')'

      # Step 1: Go through every Transaction and get a list of all
      # Transactions that are to be invested, as well as the total dollar
      # amount to be invested this week. At the same time, aggregate all old
      # Transactions into Agexes.
      amount_to_invest = 0.0
      transactions_to_invest = []
      user.transactions.each do |transaction|
        logger.info 'CRON: Processing Transaction ' + transaction.id.to_s

        if transaction.archived
          logger.info 'CRON: Skipping archived Transaction'
          # Re-archive in order to delete the Transaction if it is too old
          transaction.archive!
          next
        end

        # Archive backed_out Transactions
        if transaction.backed_out
          logger.info 'CRON: Archiving backed_out Transaction'
          transaction.archive!
          next
        end

        # Deduct Transactions
        if transaction.invested
          logger.info 'CRON: Skipping deduct for invested Transaction' +
            ', already invested ' + transaction.amount_invested.to_s
        else
          amount = transaction.amount * user.invest_percent / 100.0
          amount = amount.round(2)
          amount_to_invest += amount
          transactions_to_invest.push transaction
          logger.info 'CRON: Adding ' + amount.to_s + ' to deduct total'
        end

        # Don't aggregate/delete if Transaction is still of current month
        month = transaction.date.beginning_of_month
        unless month < current_month
          logger.info 'CRON: Not aggregating Transaction, month: ' + month.to_s
          next
        end

        # Aggregate old Transactions
        logger.info 'CRON: Aggregating Transaction, month: ' + month.to_s
        agexes = user.agexes.where(month: month)
        agex = agexes.find_by(vice_id: transaction.vice.id)
        unless agex
          logger.info 'CRON: Creating new Agex for ' + transaction.vice.name +
            ' Vice'
          agex = user.agexes.new
          agex.vice = transaction.vice
          agex.month = month
        end
        agex.amount += transaction.amount_invested
        agex.save!

        # Archive all old Transactions, even if they're included in
        # transactions_to_invest.
        transaction.archive!
        logger.info 'CRON: Successfully aggregated/deleted Transaction into ' +
         agex.id.to_s + ' Agex'
      end

      # Step 2: Deduct the total amount from the User's source Account into
      # their Deposit account. If they do not have source/deposit Accounts
      # specified or set up with Dwolla, this call will do nothing.
      user.dwolla_transfer(amount_to_invest)

      # Step 3: Mark all Transactions in transactions_to_invest as 'invested'.
      # Note, we won't check whether or not they are archived here because
      # they may have been archived by Step 1. We still want to modify their
      # 'invested' state. Step 1 will check if the Transaction was archived
      # before placing it in the transactions_to_invest array.
      transactions_to_invest.each do |transaction|
        amount = transaction.amount * user.invest_percent / 100.0
        amount = amount.round(2)
        transaction.invest!(amount)
      end
    end # User.all.each do |user|

    logger.info DateTime.current.strftime(
      "CRON: Finished weekly_deduct_cron at %Y-%m-%d %H:%M:%S::%L %z")
    head :ok
  end

  def transaction_refresh_cron
    raise NotFound unless request.remote_ip == '127.0.0.1'

    logger.info DateTime.current.strftime(
      "CRON: Start transaction_refresh_cron at %Y-%m-%d %H:%M:%S::%L %z")

    User.all.each do |user|
      logger.info 'CRON: Starting Transaction refreshing for ' + user.fname +
        ' ' + user.lname + ' (' + user.id.to_s + ')'
      user.refresh_transactions(true)
    end

    logger.info DateTime.current.strftime(
      "CRON: Finished transaction_refresh_cron at %Y-%m-%d %H:%M:%S::%L %z")
    head :ok
  end

  def dev_ratelimit
    # Empty method, route used only to test ratelimiting
    head :ok
  end

  def version_ios
    render json: { 'version' => '0.0.1' }, status: :ok
  end

  ##############################################################################
  # Calls requiring access_token
  ##############################################################################

  # None
end
