module DwollaTokenConcern
  include ErrorHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def account_token
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
      rescue ActiveRecord::RecordNotFound => _e
        if ENV['RAILS_ENV'] == 'test'
          # Create an account token if one doesn't already exist
          DwollaTokenStore.create! account_id: ENV["DWOLLA_ACCOUNT_ID"],
                                   access_token: 'insert_access_token',
                                   refresh_token: 'insert_refresh_token',
                                   expires_in: 3500
          token = DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
        else
          raise ErrorHelper::InternalServerError('account_token not found')
        end
      end
      @account_token = token
    end

    def app_token
      # Create an application token if one doesn't already exist
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: nil
      rescue ActiveRecord::RecordNotFound => _e
        $dwolla.auths.client # This gets saved in our intitializer's on_grant callback
      end
      @app_token = token
    end
  end
end
