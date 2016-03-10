
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

  def twilio_callback
    # sender = params[:From]
    # body = params[:Body]
  end

  def version_ios
    render json: { 'version' => '0.0.1' }, status: :ok
  end

  ##############################################################################
  # Calls requiring access_token
  ##############################################################################
  def todo
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
      plaid_user = Plaid.add_user('connect', params[:username],
                                  params[:password], params[:type])
    rescue Plaid::PlaidError => e
      return render json: {
        'code' => e.code,
        'message' => e.message,
        'resolve' => e.resolve
      }, status: :unauthorized
    end
    # begin
    #   plaid_user.mfa_authentication('again')
    #   plaid_user.mfa_authentication('again')
    #   plaid_user.mfa_authentication('again')
    #   plaid_user.mfa_authentication('tomato')
    # rescue Plaid::PlaidError => e
    #   return render json: {
    #     'code' => e.code,
    #     'message' => e.message,
    #     'resolve' => e.resolve
    #   }, status: :unauthorized
    # end
    render json: plaid_user, status: :ok
  end

  def todo2
    begin
      plaid_user.mfa_authentication('tomato')
    rescue Plaid::PlaidError => e
      return render json: {
        'code' => e.code,
        'message' => e.message,
        'resolve' => e.resolve
      }, status: :unauthorized
    end
    render json: plaid_user, status: :ok
  end
end
