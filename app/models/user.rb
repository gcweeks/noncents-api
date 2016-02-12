class User < ActiveRecord::Base
  has_many :accounts
  has_many :user_vices
  has_many :vices, through: :user_vices
  has_many :user_friends
  has_many :friends, through: :user_friends
  BASE58_ALPHABET = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a -
                    %w(0 O I l)
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: {
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create
  }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def as_json(_options = {})
    json = super(except: [:token, :password_digest])
    json
  end

  def with_token
    json = as_json
    json['token'] = token
    json
  end

  def generate_token!
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
