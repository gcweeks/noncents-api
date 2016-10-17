require 'dwolla_v2'

$dwolla = DwollaV2::Client.new(
  id: ENV['DWOLLA_CLIENT_ID'],
  secret: ENV['DWOLLA_CLIENT_SECRET']) do |config|

  config.environment = :sandbox
  # TODO: Implement
  # config.environment = :production

  # Whenever a token is granted, save it to ActiveRecord
  config.on_grant do |token|
    DwollaTokenStore.create! token
  end
end

# Create an application token if one doesn't already exist
begin
  DwollaTokenStore.fresh_token_by! account_id: nil
rescue ActiveRecord::RecordNotFound => _e
  $dwolla.auths.client # This gets saved in our on_grant callback
end

# Create an account token if one doesn't already exist
begin
  DwollaTokenStore.fresh_token_by! account_id: ENV["DWOLLA_ACCOUNT_ID"]
rescue ActiveRecord::RecordNotFound => _e
  DwollaTokenStore.create! account_id: ENV["DWOLLA_ACCOUNT_ID"],
                           refresh_token: ENV["DWOLLA_ACCOUNT_REFRESH_TOKEN"],
                           expires_in: -1
rescue DwollaV2::AccessDeniedError => _e
  SlackHelper.log('DwollaV2::AccessDeniedError: ' + e.inspect)
end
