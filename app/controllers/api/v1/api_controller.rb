class Api::V1::ApiController < ApplicationController
  include ApiHelper

  before_action :init
  before_action :restrict_access, except: [
    # List of route methods that do not need authentication
    :request_get,
    :request_post,
    :auth,
    :confirmation,
    :signup,
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

  def signup
    # Replacement for POST /users call so that the server is responsible for
    # populating User data.

    # Create new User
    user = User.new(user_params)
    user.generate_token!
    if user.save
      # Send User model with token
      return render json: user.with_token, status: :ok
    end
    render json: user.errors, status: :unprocessable_entity
  end
  # def phone_auth
  #   # Alternative to users_get call that returns the User token in addition to
  #   # the rest of the model, provided proper authentication is given.
  #   if params[:code].blank?
  #     return render text: "This call requires a confirmation code", status:
  #       :bad_request
  #   end
  #   if params[:user][:number].blank?
  #     return render text: "This call requires a phone number (user[number])",
  #       status: :bad_request
  #   end
  #   unless confirm_code(params[:user][:number], params[:code])
  #     return render json: {"confirmation" => "rejected"}, status: :ok
  #   end
  #   user = User.where(number: params[:user][:number]).first
  #   return head :not_found unless user
  #   if user.token.blank?
  #     # Generate access token for User
  #     user.generate_token!
  #     user.save!
  #   end
  #   # Send User model with token
  #   return render json: user.with_token, status: :ok
  # end
  # def confirmation
  #   return head :bad_request if params[:number].blank?
  #   if sms_send_confirmation(params[:number])
  #     return render json: {"confirmation" => "sent"}, status: :ok
  #   end
  #   return render json: {"confirmation" => "invalid"}, status: :ok
  # end
  # def phone_signup
  #   # Replacement for users_post call so that the server is responsible for
  #   # populating User data.
  #   if params[:code].blank?
  #     return render text: "This call requires a confirmation code", status:
  #       :bad_request
  #   end
  #   if (params[:user][:number].blank? || params[:user][:fname].blank? ||
  #     params[:user][:lname].blank?)
  #
  #     return render text: "This call requires a name (user[fname],
  #       user[lname]) and phone number (user[number])", status: :bad_request
  #   end
  #   unless confirm_code(params[:user][:number], params[:code])
  #     return render json: {"confirmation" => "rejected"}, status: :ok
  #   end
  #
  #   # See if User exists already
  #   user = User.where(number: params[:number]).first
  #   unless user
  #     # Create new User
  #     user = User.new
  #     user.fname = params[:user][:fname].strip
  #     user.lname = params[:user][:lname].strip
  #     user.number = params[:user][:number]
  #     user.generate_token!
  #     user.save!
  #   end
  #   unless user.token
  #     # Generate access token for User
  #     user.generate_token!
  #     user.save!
  #   end
  #
  #   # Send User model with token
  #   return render json: user.with_token, status: :ok
  # end

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

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :password, :number, :dob,
                                 :email, :invest_percent)
  end
end
