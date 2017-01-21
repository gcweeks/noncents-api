class Bank < ApplicationRecord
  belongs_to :user
  has_many :accounts

  validates :name, presence: true
  validates :access_token, presence: true
  validates :user, presence: true

  def refresh_balances
    plaid_user = Plaid::User.load(:auth, self.access_token)
    begin
      plaid_user.balance
    rescue Plaid::PlaidError => e
      if e.code == 1215
        # Invalid credentials, need to submit PATCH call to resolve
        self.plaid_needs_reauth = true
        save!
      else
        status = case e
                 when Plaid::BadRequestError
                   'bad_request'
                 when Plaid::UnauthorizedError
                   'unauthorized'
                 when Plaid::RequestFailedError
                   'payment_required'
                 when Plaid::NotFoundError
                   'not_found'
                 when Plaid::ServerError
                   'internal_server_error'
                 else
                   'internal_server_error'
                 end
        logger.warn('Plaid Error: (' + e.code.to_s + ') ' + e.message + '. ' +
                    e.resolve + ' [' + status + ']')
        SlackHelper.log("Plaid Error\n`" + e.code.to_s + "`\n```" +
          e.message + "\n" + e.resolve + "\n" + status + '```')
      end
      return false
    rescue => e
      logger.warn e.inspect
      SlackHelper.log('Bank.refresh_balances error: ```' +
        e.inspect + '```')
      return false
    end

    # Populate balance (and all other data) with new plaid_user data
    self.user.populate_accounts(plaid_user, true)

    true
  end
end
