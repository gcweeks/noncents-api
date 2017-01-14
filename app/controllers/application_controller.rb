class ApplicationController < ActionController::API
  include ErrorHelper
  rescue_from BadRequest, :with => :bad_request
  rescue_from Unauthorized, :with => :unauthorized
  rescue_from PaymentRequired, :with => :payment_required
  rescue_from NotFound, :with => :not_found
  rescue_from UnprocessableEntity, :with => :unprocessable_entity
  rescue_from InternalServerError, :with => :internal_server_error

  def init
    @SALT = ENV['SALT']
  end

  def restrict_access
    token = request.headers['Authorization']
    return head :unauthorized unless token
    @authed_user = User.find_by(token: token)
    return head :unauthorized unless @authed_user
  end

  def restrict_access_admin
    token = params[:access_token]
    token = request.headers['Authorization'] unless token
    # return head :unauthorized unless token == ENV['ADMIN_TOKEN']
  end

  private

  def bad_request(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :bad_request
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :bad_request
  end

  def unauthorized(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :unauthorized
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :unauthorized
  end

  def payment_required(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :payment_required
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :payment_required
  end

  def not_found(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :not_found
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :not_found
  end

  def unprocessable_entity(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :unprocessable_entity
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :unprocessable_entity
  end

  def internal_server_error(exception)
    if exception.data
      ExceptionNotifier.notify_exception(exception,
        env: request.env, data: {:response => exception.data.as_json}
      )
      return render json: exception.data, status: :internal_server_error
    end

    ExceptionNotifier.notify_exception(exception, env: request.env)
    head :internal_server_error
  end
end
