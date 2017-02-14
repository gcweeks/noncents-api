module UserHelper
  include ErrorHelper

  def mfa_or_populate(user, plaid_user, product, bank_name = nil)
    # Find existing Bank or create new one
    bank = user.banks.find_by(access_token: plaid_user.access_token)
    unless bank
      raise InternalServerError unless bank_name
      bank = user.banks.new(name: bank_name,
                            access_token: plaid_user.access_token)
      raise InternalServerError.new(bank.errors) unless bank.valid?
      bank.save!
    end

    if plaid_user.mfa?
      # MFA
      ret = plaid_user.instance_values.slice 'access_token', 'mfa_type', 'mfa'
      return ret
    end

    # No MFA required
    ret = user.populate_accounts(plaid_user)
    # 'ret' will either be a successfully saved User model or an ActiveRecord
    # error hash.
    raise InternalServerError.new(ret) unless ret.is_a?(User)

    # Store success state in Bank model
    if product == 'auth'
      bank.plaid_auth = true
    else # connect
      bank.plaid_connect = true
    end
    raise InternalServerError.new(bank.errors) unless bank.valid?
    bank.save!

    ret
  end

  def get_plaid_error(e)
    errors = {
      'code' => e.code,
      'message' => e.message,
      'resolve' => e.resolve
    }
    # Don't send Slack notifications for common cases
    common = [
      1200, 1201, 1202 # invalid credentials
    ]
    if common.include? e.code
      logger.info errors
      return nil
    end

    case e
    when Plaid::BadRequestError
      BadRequest.new(errors)
    when Plaid::UnauthorizedError
      Unauthorized.new(errors)
    when Plaid::RequestFailedError
      PaymentRequired.new(errors)
    when Plaid::NotFoundError
      NotFound.new(errors)
    when Plaid::ServerError
      InternalServerError.new(errors)
    else
      InternalServerError.new(errors)
    end
  end
end
