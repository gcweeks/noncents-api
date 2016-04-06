class User < ActiveRecord::Base
  include ActiveModel::Serializers::JSON
  has_many :accounts
  has_many :banks
  has_many :user_vices
  has_many :vices, through: :user_vices
  has_many :transactions
  has_many :agexes
  has_many :user_friends
  has_many :friends, through: :user_friends
  has_one  :fund
  has_secure_password
  BASE58_ALPHABET = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a -
                    %w(0 O I l)
  PASSWORD_FORMAT = /\A
    (?=.{8,})          # Must contain 8 or more characters
    (?=.*\d)           # Must contain a digit
    (?=.*[a-z])        # Must contain a lower case character
    (?=.*[A-Z])        # Must contain an upper case character
    # (?=.*[[:^alnum:]]) # Must contain a symbol
  /x

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
      include: [:fund],
      except: [:token, :password_digest]
    }.merge(options))
    # 'include' wasn't calling as_json
    json['accounts'] = accounts
    json['transactions'] = transactions
    json['agexes'] = agexes

    json['vices'] = vices.map(&:name)
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
end
