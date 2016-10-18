module DwollaTokenConcern
  include ErrorHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def account_token
      # Create an account token if one doesn't already exist
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
      rescue ActiveRecord::RecordNotFound => _e
        raise ErrorHelper::InternalServerError('account_token not found')
      end
      @account_token ||= token
    end

    def app_token
      # Create an application token if one doesn't already exist
      begin
        token = DwollaTokenStore.fresh_token_by! account_id: nil
      rescue ActiveRecord::RecordNotFound => _e
        $dwolla.auths.client # This gets saved in our intitializer's on_grant callback
      end
      @app_token ||= token
    end
  end
end
