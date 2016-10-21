class DwollaTokenStore < ApplicationRecord
  DESIRED_FRESHNESS = 1.minute
  SECRET_KEY = ENV['SECRET_KEY']

  attr_encrypted :access_token, key: SECRET_KEY
  attr_encrypted :refresh_token, key: SECRET_KEY

  # Look in dwolla_token_store table for the most recent token matching the
  # given criteria. If one does not exist, throw an
  # 'ActiveRecord::RecordNotFound' error. If one does exist, convert the
  # 'DwollaTokenStore' to a fresh 'DwollaV2::Token' (see '#to_fresh_token')
  def self.fresh_token_by! criteria
    connection.clear_query_cache
    where(criteria)
      .order(created_at: :desc)
      .first!
      .to_fresh_token
  end

  def to_fresh_token
    if expired?
      # If the token store is expired, either refresh the token (account token)
      # or get a new token (app token).
      account_id? \
        ? $dwolla.auths.refresh(self) \
        : $dwolla.auths.client
    else
      # If the token is not expired, just convert it to a DwollaV2::Token
      # $dwolla.tokens.new(self)
      $dwolla.tokens.new(self)
    end
  end

  private

  def expired?
    return false if expires_in < 0
    created_at < Time.now.utc - expires_in.seconds + DESIRED_FRESHNESS
  end
end
