module UserHelper
  include ErrorHelper
  def set_bank(user, type, access_token)
    # Find existing Bank or create new one
    bank = user.banks.find_by(access_token: access_token)
    unless bank
      bank = user.banks.new(name: type, access_token: access_token)
      bank.save!
    end
    true
  end

  def render_mfa_or_populate(user, plaid_user)
    if plaid_user.mfa?
      # MFA
      ret = plaid_user.instance_values.slice 'access_token', 'mfa_type', 'mfa'
      return ret
    end

    # No MFA required
    # Add 'auth' product to get full account numbers
    begin
      plaid_user = plaid_user.upgrade(:auth)
    rescue Plaid::PlaidError => e
      return get_plaid_error(e)
    end
    ret = populate_user_accounts(user, plaid_user)
    # 'ret' will either be a successfully saved User model or an ActiveRecord
    # error hash.
    return InternalServerError.new(ret) unless ret.is_a?(User)
    ret
  end

  def get_plaid_error(e)
    errors = {
      'code' => 'e.code',
      'message' => e.message,
      'resolve' => e.resolve
    }
    return case e
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

  private

  def populate_user_accounts(user, plaid_user)
    bank = user.banks.find_by(access_token: plaid_user.access_token)
    # This method idempotently populates user's Accounts with accounts given in
    # plaid_user, then returns either a successfully saved User model or an
    # error hash.
    plaid_user.accounts.each do |plaid_account|
      # Get existing Account or create new one
      account = nil
      user.accounts.each do |user_account|
        if plaid_account.id == user_account.plaid_id
          account = user_account
          break
        end
      end if user.accounts
      # Create new Account if one wasn't found in loop above
      unless account
        account = user.accounts.new
        account.bank = bank
        account.plaid_id = plaid_account.id
        if plaid_account.numbers
          account.routing_num = plaid_account.numbers[:routing]
          account.account_num = plaid_account.numbers[:account]
        else
          account.account_num = plaid_account.meta['number']
        end
      end

      # Populate Account details (or update details if Account already exists)
      account.name = plaid_account.meta['name']
      account.account_type = plaid_account.type.to_s
      account.account_subtype = plaid_account.subtype
      account.institution = plaid_account.institution.to_s
      return account.errors unless account.valid?
      account.save!
    end if plaid_user.accounts

    user
  end
end
