module DwollaHelper
  require 'dwolla_v2'

  $dwolla = DwollaV2::Client.new(
    id: 'XIvRyGL2IFvDNc0tGukSoTZ7yW9dCaZm6hwjzxaU2p5QhbWKTC',
    secret: 'iscddv6GIjS4S3iKpLxFQD5002hkN4GheNGE2GE3JQnbZOOTSX') do |config|

    config.environment = :sandbox
    # config.environment = :production
  end

  @@account_token = $dwolla.tokens.new(
    access_token: 'CekeHk4k3ZTcIxyfUpFhncAqGtrz1RVThB92Nmrhja3Ms8XoYg',
    refresh_token: 'X0ZOfXjHv7wpLfwBc3czViQqhTgHxkWJK7tGjvarhhmZj570cS',
    account_id: '8626764c-406d-4b40-aedb-4d70db59957a')

  def self.add_customer(user)
    # jenny = DwollaSwagger::CreateCustomer.new
    # jenny.first_name = user.fname
    # jenny.last_name = user.lname
    # jenny.email = user.email
    # begin
    #   location = DwollaSwagger::CustomersApi.create(body: jenny)
    # rescue DwollaSwagger::ClientError => _e
    #   # p eval(e.message)
    #   return { error: 400 }
    # rescue DwollaSwagger::ServerError => _e
    #   # p eval(e.message)
    #   return { error: 500 }
    # end
    # { location: location }
  end

  def self.get_funding_source(id)
    funding_sources = @@account_token.get('https://api-uat.dwolla.com/customers/' + id + '/funding-sources')
    # funding_sources._embedded['funding-sources'][0].name # => "Vera Brittain’s Checking"
    return funding_sources
  end

  def self.add_funding_source(customer_id)
    request_body = {
      routingNumber: '222222226',
      accountNumber: '123456789',
      type: 'checking',
      name: 'Vera Brittain’s Checking'
    }

    funding_source = @@account_token.post('https://api-uat.dwolla.com/customers/' + customer_id + '/funding-sources', request_body)
    # funding_source.headers[:location] # => "https://api-uat.dwolla.com/funding-sources/375c6781-2a17-476c-84f7-db7d2f6ffb31"
    return funding_source
  end

  def self.transfer_money(customer_id, funding_source, amount)
    request_body = {
      _links: {
        destination: {
          href: 'https://api-uat.dwolla.com/customers/' + customer_id
        },
        source: {
          href: 'https://api-uat.dwolla.com/funding-sources/' + funding_source
        }
      },
      amount: {
        currency: 'USD',
        value: amount.to_s
      },
      metadata: {
        foo: 'bar',
        baz: 'boo'
      }
    }

    transfer = @@account_token.post "transfers", request_body
    return transfer.headers[:location] # => "https://api.dwolla.com/transfers/74c9129b-d14a-e511-80da-0aa34a9b2388"
  end
end
