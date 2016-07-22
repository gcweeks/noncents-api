class User < ActiveRecord::Base
  include ActiveModel::Serializers::JSON
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
  has_many :banks
  has_many :user_vices
  has_many :vices, through: :user_vices
  has_many :transactions
  has_many :agexes
  has_many :user_friends
  has_many :friends, through: :user_friends
  has_one  :fund
  has_one  :address
  has_many :yearly_funds
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

  def as_json(options = {})
    json = super({
      include: [:fund, :address],
      except: [:token, :password_digest]
    }.merge(options))
    # 'include' wasn't calling as_json
    json['accounts'] = accounts
    json['agexes'] = agexes
    json['transactions'] = transactions
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

  def dwolla_create
    # TODO: Implement
    # DwollaHelper.add_customer(self)
  end

  # Add funding source and destination to Dwolla
  def dwolla_add_funding_source
    # TODO: Implement
    # DwollaHelper.add_funding_source(customer_id)
  end

  def dwolla_transfer(amount)
    # TODO: Implement
    # begin
    #   ret = DwollaHelper.transfer_money(customer_id, funding_source, amount)
    # rescue DwollaV2::NotFoundError => e
    #   p "NOT FOUND"
    #   p e
    #   # => #<DwollaV2::NotFoundError status=404 headers={"server"=>"cloudflare-nginx", "date"=>"Mon, 28 Mar 2016 15:35:32 GMT", "content-type"=>"application/vnd.dwolla.v1.hal+json; profile=\"http://nocarrier.co.uk/profiles/vnd.error/\"; charset=UTF-8", "content-length"=>"69", "connection"=>"close", "set-cookie"=>"__cfduid=da1478bfdf3e56275cd8a6a741866ccce1459179332; expires=Tue, 28-Mar-17 15:35:32 GMT; path=/; domain=.dwolla.com; HttpOnly", "access-control-allow-origin"=>"*", "x-request-id"=>"667fca74-b53d-43db-bddd-50426a011881", "cf-ray"=>"28ac270abca64207-MSP"} {"code"=>"NotFound", "message"=>"The requested resource was not found."}>
    #
    #   p e.status
    #   # => 404
    #
    #   p e.headers
    #   # => {"server"=>"cloudflare-nginx", "date"=>"Mon, 28 Mar 2016 15:35:32 GMT", "content-type"=>"application/vnd.dwolla.v1.hal+json; profile=\"http://nocarrier.co.uk/profiles/vnd.error/\"; charset=UTF-8", "content-length"=>"69", "connection"=>"close", "set-cookie"=>"__cfduid=da1478bfdf3e56275cd8a6a741866ccce1459179332; expires=Tue, 28-Mar-17 15:35:32 GMT; path=/; domain=.dwolla.com; HttpOnly", "access-control-allow-origin"=>"*", "x-request-id"=>"667fca74-b53d-43db-bddd-50426a011881", "cf-ray"=>"28ac270abca64207-MSP"}
    #
    #   p e.code
    #   # => "NotFound"
    #   return head status: :unprocessable_entity
    # rescue DwollaV2::Error => e
    #   p "ERROR"
    #   p e
    #   return head status: :unprocessable_entity
    # end
  end

  # Convenience method for getting the yearly_fund matching the current year
  # TODO Eventually let User decide their own contribution date, e.g. during
  # Jan-Mar when they haven't deposited their $5500 max.
  def yearly_fund
    year = Date.current.year # e.g. 2016 (Integer)
    yearly_fund = self.yearly_funds.where(year: year).first
    return yearly_fund unless yearly_fund.nil?
    # No yearly_fund model found matching this year, create one
    yearly_fund = self.yearly_funds.new(year: year)
    yearly_fund.save!
    yearly_fund
  end
end
