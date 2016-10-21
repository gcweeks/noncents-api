ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock'
include WebMock::API
WebMock.enable!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def fixture(name)
    JSON.parse(File.read('test/fixtures/files/' + name + '.json')).to_json
  end

  def stub_plaid(method, path, body: {}, query: {}, status: 200, response: nil,
               host: 'tartan.plaid.com')
    response = fixture(response) if response.is_a?(Symbol)

    headers = {}
    headers['Content-Type'] = 'application/x-www-form-urlencoded' \
      if method != :get

    body.merge!(
      "client_id" => Plaid.client.client_id,
      "secret" => Plaid.client.secret
    )

    expectations = {}
    expectations[:headers] = headers unless headers.empty?
    expectations[:body] = body unless body.empty?
    expectations[:query] = query unless query.empty?

    stub = stub_request(method, "https://#{host}/#{path}")
    stub = stub.with(expectations) unless expectations.empty?
    stub.to_return(status: status, body: response)
  end

  # Add more helper methods to be used by all tests here...
end
