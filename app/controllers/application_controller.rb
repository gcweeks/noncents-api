class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For non-APIs, you may want to use :exception instead.
  protect_from_forgery with: :null_session

  def init
    @SALT = ENV['SALT']
  end

  def restrict_access
    token = params[:access_token]
    return head :unauthorized unless token
    @authed_user = User.where(token: token).first
    return head :unauthorized unless @authed_user
  end

  def ssl_configured?
    !Rails.env.development?
  end

  def staging_server?
    ENV['DOMAIN'] != "dimention.co"
  end
end
