class Api::V1::ApiController < ApplicationController
  include ApiHelper

  before_action :init
  before_action :restrict_access, except: [
    # List of route methods that do not need authentication
    :request_get,
    :request_post,
    :auth,
    :signup,
    :check_email,
    :twilio_callback,
    :weekly_deduct_cron,
    :transaction_refresh_cron,
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
      return render json: errors, status: :bad_request
    end
    if params[:user][:email].blank?
      errors = { email: ['cannot be blank'] }
      return render json: errors, status: :bad_request
    end
    if params[:user][:password].blank?
      errors = { password: ['cannot be blank'] }
      return render json: errors, status: :bad_request
    end
    user = User.find_by(email: params[:user][:email])
    return head :not_found unless user
    user = user.try(:authenticate, params[:user][:password])
    unless user
      errors = { password: ['is incorrect'] }
      return render json: errors, status: :unauthorized
    end
    if user.token.blank?
      # Generate access token for User
      user.generate_token
      # Save and check for validation errors
      render json: user.errors, status: :unprocessable_entity unless user.save
    end
    # Send User model with token
    render json: user.with_token, status: :ok
  end

  def check_email
    user = User.find_by(email: params[:email])
    return render json: { 'email' => 'exists' }, status: :ok if user
    render json: { 'email' => 'does not exist' }, status: :ok
  end

  def weekly_deduct_cron
    return head :not_found unless request.remote_ip == '127.0.0.1'

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
    head status: :ok
  end

  def transaction_refresh_cron
    return head :not_found unless request.remote_ip == '127.0.0.1'

    logger.info DateTime.current.strftime(
      "CRON: Start transaction_refresh_cron at %Y-%m-%d %H:%M:%S::%L %z")

    User.all.each do |user|
      logger.info 'CRON: Starting Transaction refreshing for ' + user.fname +
        ' ' + user.lname + ' (' + user.id.to_s + ')'
      user.refresh_transactions(true)
    end

    logger.info DateTime.current.strftime(
      "CRON: Finished transaction_refresh_cron at %Y-%m-%d %H:%M:%S::%L %z")
    head status: :ok
  end

  def version_ios
    render json: { 'version' => '0.0.1' }, status: :ok
  end

  ##############################################################################
  # Calls requiring access_token
  ##############################################################################
end
