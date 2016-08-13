module UserHelper
  def populate_user_accounts(user, plaid_user)
    # This method idempotently populates user's Accounts with accounts given in
    # plaid_user, then returns either a successfully saved User model or an
    # error hash.
    plaid_user.accounts.each do |plaid_account|
      account = nil
      user.accounts.each do |user_account|
        if plaid_account.id == user_account.plaid_id
          account = user_account
          break
        end
      end if user.accounts
      # Create new Account if one wasn't found in loop above
      account = user.accounts.new unless account
      # Populate Account details
      account.plaid_id = plaid_account.id
      account.name = plaid_account.meta['name']
      account.account_type = plaid_account.type.to_s
      account.account_subtype = plaid_account.subtype
      account.institution = plaid_account.institution.to_s
      if plaid_account.numbers
        account.routing_num = plaid_account.numbers[:routing]
        account.account_num = plaid_account.numbers[:account]
      else
        account.account_num = plaid_account.meta['number']
      end
      return account.errors unless account.valid?
      account.save!
    end if plaid_user.accounts

    user
  end

  def set_bank(type, access_token)
    bank = @authed_user.banks.new(name: type, access_token: access_token)
    bank.save!
  end

  def render_mfa_or_populate(plaid_user)
    if plaid_user.mfa?
      # MFA
      ret = plaid_user.instance_values.slice 'access_token', 'mfa_type', 'mfa'
      return render json: ret, status: :ok
    end

    # No MFA required
    ret = populate_user_accounts(@authed_user, plaid_user)
    # 'ret' will either be a successfully saved User model or an ActiveRecord
    # error hash.
    unless ret.is_a? User
      return render json: ret, status: :internal_server_error
    end
    render json: ret, status: :ok
  end
end
