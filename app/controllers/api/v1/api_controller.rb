
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

    if params[:user][:email].blank?
      errors = { email: ['cannot be blank'] }
      return render json: errors, status: :bad_request
    end
    if params[:user][:password].blank?
      errors = { password: ['cannot be blank'] }
      return render json: errors, status: :bad_request
    end
    user = User.where(email: params[:user][:email]).first
    return head :not_found unless user
    user = user.try(:authenticate, params[:user][:password])
    unless user
      errors = { password: ['is incorrect'] }
      return render json: errors, status: :unauthorized
    end
    if user.token.blank?
      # Generate access token for User
      user.generate_token!
      user.save!
    end
    # Send User model with token
    render json: user.with_token, status: :ok
  end

  def check_email
    user = User.where(email: params[:email]).first
    return render json: { 'email' => 'exists' }, status: :ok if user
    render json: { 'email' => 'does not exist' }, status: :ok
  end

  def twilio_callback
    # sender = params[:From]
    # body = params[:Body]
    # return render text: ""
  end

  def version_ios
    render json: { 'version' => '0.0.1' }, status: :ok
  end

  ##############################################################################
  # Calls requiring access_token
  ##############################################################################
  def test
  end

  def todo
    # Get Plaid user
    begin
      plaid_user = Plaid.add_user('auth', 'plaid_test', 'plaid_good', 'wells')
    rescue Plaid::PlaidError => e
      return render json: {
        'code' => e.code,
        'message' => e.message,
        'resolve' => e.resolve
      }, status: :unauthorized
    end

    @authed_user.accounts = [] unless @authed_user.accounts
    user_accounts = @authed_user.accounts

    plaid_user.accounts.each do |plaid_account|
      catch :has_account do
        user_accounts.each do |user_account|
          throw :has_account if plaid_account.id == user_account.plaid_id
        end
        new_account = @authed_user.accounts.new
        new_account.plaid_id = plaid_account.id
        new_account.name = plaid_account.name
        new_account.account_type = plaid_account.type
        new_account.account_subtype = plaid_account.subtype
        new_account.institution = plaid_account.institution_type
        new_account.routing_num = plaid_account.numbers['routing']
        new_account.account_num = plaid_account.numbers['account']
        unless new_account.valid?
          return render json: new_account.errors.messages, status:
            :internal_server_error
        end
        new_account.save!
      end
    end

    render json: @authed_user, status: :ok
  end
end
