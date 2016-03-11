module UserHelper
  def populate_user_accounts(user, plaid_user)
    # This method returns either a successfully saved User model or an error
    # hash.
    plaid_user.accounts.each do |plaid_account|
      account = nil
      user.accounts.each do |user_account|
        if plaid_account.id == user_account.plaid_id
          account = user_account
          break
        end
      end if user.accounts
      account = user.accounts.new unless account
      account.plaid_id = plaid_account.id
      account.name = plaid_account.name
      account.account_type = plaid_account.type
      account.account_subtype = plaid_account.subtype
      account.institution = plaid_account.institution_type
      account.routing_num = plaid_account.numbers['routing']
      account.account_num = plaid_account.numbers['account']
      return account.errors unless account.valid?
      account.save!
    end if plaid_user.accounts

    user
  end

  def set_bank(type, access_token)
    bank = @authed_user.banks.new(name: type, access_token: access_token)
    bank.save!
  end
end
