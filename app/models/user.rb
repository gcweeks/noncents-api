class User < ApplicationRecord
  include ViceParser
  BASE58_ALPHABET = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a -
  %w(0 O I l)
  PASSWORD_FORMAT = /\A
  (?=.{8,})          # Must contain 8 or more characters
  (?=.*\d)           # Must contain a digit
  (?=.*[a-z])        # Must contain a lower case character
  (?=.*[A-Z])        # Must contain an upper case character
  # (?=.*[[:^alnum:]]) # Must contain a symbol
  /x

  has_many :accounts
  has_many :agexes
  has_many :auth_events
  has_many :banks
  has_many :dwolla_transactions
  has_many :fcm_tokens
  has_many :transactions
  has_many :user_vices
  has_many :vices, through: :user_vices
  has_many :yearly_funds
  has_one  :address
  has_one  :fund
  belongs_to :source_account, :class_name => "Account", optional: true
  belongs_to :deposit_account, :class_name => "Account", optional: true
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: true, format: {
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  }
  validates :password, presence: true, format: { with: PASSWORD_FORMAT },
                       on: :create
  validates :password, allow_nil: true, format: { with: PASSWORD_FORMAT },
                       on: :update
  validates :fname, presence: true
  validates :lname, presence: true
  validates :invest_percent, inclusion: 0..100
  validates :dob, presence: true
  validates :token, presence: true
  validates :fund, presence: true
  validates :goal, inclusion: 1..5500
  validate :valid_phone?

  def valid_phone?
    if self.phone
      phone = self.phone
      # Check if number is exactly 10 digits (Convert to int then back to
      # string, then make sure result is the same. Pad with zeros in case phone
      # starts with zero, as this would drop out in integer conversion.)
      if phone.length != 10 || ("%010d" % phone.to_i.to_s != phone)
        errors.add(:phone, 'must be exactly 10 digits')
      end
      return
    end
    errors.add(:phone, 'is required')
  end

  def as_json(options = {})
    json = super({
      except:  [:token, :password_digest, :dwolla_id, :reset_password_token,
                :reset_password_sent_at, :confirmation_token,
                :confirmation_sent_at, :failed_attempts, :unlock_token,
                :locked_at, :source_account_id, :deposit_account_id]
    }.merge(options))
    # Manually call as_json
    json['accounts'] = accounts
    json['address'] = address
    json['agexes'] = agexes
    json['deposit_account'] = deposit_account
    json['fund'] = fund
    json['source_account'] = source_account
    json['transactions'] = transactions.reject { |t| t.archived }
    json['vices'] = vices.map(&:name)
    json['yearly_funds'] = yearly_funds
    json
  end

  def with_token
    json = as_json
    json['token'] = token
    json
  end

  def generate_token
    # Generate token using Rails 4's ActiveRecord SecureToken implementation:
    # SecureRandom.base58(24)
    token = SecureRandom.random_bytes(24).unpack('C*').map do |byte|
      idx = byte % 64
      idx = SecureRandom.random_number(58) if idx >= 58
      BASE58_ALPHABET[idx]
    end.join
    self.token = token
  end

  def dwolla_create(ssn, ip)
    return false unless self.address && ssn && ip
    res = DwollaHelper.add_customer(self, ssn, ip)
    if res.nil? || res.class != String
      logger.warn 'Error in dwolla_create'
      return false
    end

    self.dwolla_id = res
    self.save!
    true
  end

  # Add funding source and destination to Dwolla
  def dwolla_add_funding_sources
    # Delete old funding sources
    ret = self.dwolla_remove_funding_sources

    # Add new funding sources
    if self.source_account
      res = DwollaHelper.add_funding_source(self, self.source_account)
      if res.nil?
        logger.warn "dwolla_add_funding_sources failed for source account"
        ret = false
      end
      self.source_account.dwolla_id = res
      self.source_account.save!
    end
    if self.deposit_account
      res = DwollaHelper.add_funding_source(self, self.deposit_account)
      if res.nil?
        logger.warn "dwolla_add_funding_sources failed for deposit account"
        ret = false
      end
      self.deposit_account.dwolla_id = res
      self.deposit_account.save!
    end
    ret
  end

  # Remove all accounts except funding source and destination from Dwolla
  def dwolla_remove_funding_sources
    unless DwollaHelper.remove_funding_sources(self)
      logger.warn "dwolla_remove_funding_sources failed"
      return false
    end
    true
  end

  def dwolla_transfer(amount)
    # Must have source/deposit accounts
    unless self.source_account && self.source_account.dwolla_id &&
           self.deposit_account && self.deposit_account.dwolla_id &&
           amount >= 1.00

      return false
    end

    # Get balance funding source
    balance = DwollaHelper.get_balance_funding_source(self)
    return false unless balance


    if DwollaHelper.transfer_money(balance,
                                   self.source_account.dwolla_id,
                                   self.deposit_account.dwolla_id,
                                   amount.to_s)

      self.fund.deposit!(amount)
      self.yearly_fund().deposit!(amount)
      return true
    end
    false
  end

  # Convenience method for getting the yearly_fund matching the current year
  # TODO Eventually let User decide their own contribution date, e.g. during
  # Jan-Mar when they haven't deposited their $5500 max.
  def yearly_fund
    year = Date.current.year # e.g. 2016 (Integer)
    yearly_fund = self.yearly_funds.find_by(year: year)
    return yearly_fund unless yearly_fund.nil?
    # No yearly_fund model found matching this year, create one
    yearly_fund = self.yearly_funds.new(year: year)
    yearly_fund.save!
    yearly_fund
  end

  def refresh_transactions(ignore_old)
    # Get transactions from Plaid. Plaid delivers transactions on a per-bank
    # basis, but they allow filtering by account which saves some time.
    self.banks.each do |bank|
      # Get Plaid model
      begin
        plaid_user = Plaid::User.load(:connect, bank.access_token)
        transactions = plaid_user.transactions
      rescue Plaid::PlaidError => e
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
        logger.warn 'Plaid Error: (' + e.code.to_s + ') ' + e.message + '. ' +
          e.resolve + ' [' + status + ']'
        next
      end
      # Push Transaction if it is from an Account that the User has added and
      # matches one of the User's Vices.
      transactions.each do |plaid_transaction|
        # Skip Transactions without categories, because it means we can't
        # associate it with a Vice anyway.
        next unless plaid_transaction.category_hierarchy
        # Skip Transactions with negative amounts
        next unless plaid_transaction.amount > 0.0
        # Skip Transactions created more than 2 weeks ago
        next if ignore_old && plaid_transaction.date < Date.current - 2.weeks
        # Skip Transactions that the User already has, including archived
        # Transactions.
        transaction_ids = self.transactions.map(&:plaid_id)
        next if transaction_ids.include? plaid_transaction.id
        # Skip Transactions for Accounts that the User has not told us to track
        account_ids = self.accounts.map(&:plaid_id)
        # Skip transactions that don't apply to the User's Accounts
        next unless account_ids.include? plaid_transaction.account_id
        # Get Vice model via category, subcategory, and sub-subcategory
        vice = get_vice(plaid_transaction.category_hierarchy[0],
                        plaid_transaction.category_hierarchy[1],
                        plaid_transaction.category_hierarchy[2])
        # Skip all Transactions that aren't classified as a particular Vice
        next if vice.nil?
        next unless self.vices.include? vice
        # Create Transaction
        transaction = Transaction.from_plaid(plaid_transaction)
        account = Account.find_by(plaid_id: plaid_transaction.account_id)
        transaction.account = account
        transaction.vice = vice
        transaction.user = self
        transaction.save!
      end if plaid_user.transactions
    end
    self.transactions_refreshed_at = DateTime.current
    self.save!
  end
end
