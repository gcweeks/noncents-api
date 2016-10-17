module DwollaTokenConcern
  extend ActiveSupport::Concern

  module ClassMethods
    def account_token
      # Create an account token if one doesn't already exist
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
      rescue ActiveRecord::RecordNotFound => _e
        DwollaTokenStore.create! account_id: ENV["DWOLLA_ACCOUNT_ID"],
                                 refresh_token: ENV["DWOLLA_ACCOUNT_REFRESH_TOKEN"],
                                 expires_in: -1
        token = DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
      end
      @account_token ||= token
    end

    def app_token
      # Create an application token if one doesn't already exist
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: nil
      rescue ActiveRecord::RecordNotFound => _e
        token = $dwolla.auths.client # This gets saved in our on_grant callback
      end
      @app_token ||= token
    end
  end
end
