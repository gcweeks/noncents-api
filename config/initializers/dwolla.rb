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
