class Api::V1::ApiController < ApplicationController
  include ApiHelper

  before_action :init
  before_action :restrict_access, :except => [
    # List of route methods that do not need authentication
    :request_get,
    :request_post,
    :auth,
    :confirmation,
    :signup,
    :twilio_callback,
    :version_ios
  ]

###############################################################################
# Calls that don't require access_token
###############################################################################
  def request_get
    render json: {"body" => "GET Request"}, status: :ok
  end
  def request_post
    render json: {"body" => "POST Request: #{request.body.read}"}, status: :ok
  end
  def auth
    # Alternative to users_get call that returns the User token in addition to
    # the rest of the model, provided proper authentication is given.
    if params[:code].blank?
      return render text: "This call requires a confirmation code", status: :bad_request
    end
    if params[:number].blank?
      return render text: "This call requires a phone number", status: :bad_request
    end
    unless confirm_code(params[:number], params[:code])
      return render json: {"confirmation" => "rejected"}, status: :ok
    end
    user = User.where(number: params[:number]).first
    return head :not_found unless user
    if user.token.blank?
      # Generate access token for User
      user.generate_token!
      user.save!
    end
    # Send User model with token
    return render json: user.with_token, status: :ok
  end
  def confirmation
    return head :bad_request if params[:number].blank?
    if sms_send_confirmation(params[:number])
      return render json: {"confirmation" => "sent"}, status: :ok
    end
    return render json: {"confirmation" => "invalid"}, status: :ok
  end
  def signup
    # Replacement for users_post call so that the server is responsible for
    # populating User data.
    if params[:code].blank?
      return render text: "This call requires a confirmation code", status: :bad_request
    end
    if (params[:number].blank? || params[:fname].blank? || params[:lname].blank?)
      return render text: "This call requires a name and phone number", status: :bad_request
    end
    unless confirm_code(params[:number], params[:code])
      return render json: {"confirmation" => "rejected"}, status: :ok
    end
    # See if User exists already
    user = User.where(number: params[:number]).first
    unless user
      # Create new User
      user = User.create()
      user.fname = params[:fname].strip
      user.lname = params[:lname].strip
      user.number = params[:number]
      user.generate_token!
      user.save!
    end
    unless user.token
      # Generate access token for User
      user.generate_token!
      user.save!
    end
    # Send User model with token
    return render json: user.with_token, status: :ok
  end
  def twilio_callback
    # sender = params[:From]
    # body = params[:Body]
    # return render text: ""
  end
  def version_ios
    render json: {"version" => "0.0.1"}, status: :ok
  end

###############################################################################
# Calls requiring access_token
###############################################################################
  def test
    return render json: @authed_user, status: :ok
  end
end
