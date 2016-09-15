class ApplicationController < ActionController::API
  def init
    @SALT = ENV['SALT']
  end

  def restrict_access
    token = request.headers['Authorization']
    return head :unauthorized unless token
    @authed_user = User.find_by(token: token)
    return head :unauthorized unless @authed_user
  end
end
