module DwollaHelper
  require 'dwolla_v2'

  $dwolla = DwollaV2::Client.new(
    id: ENV['DWOLLA_CLIENT_ID'],
    secret: ENV['DWOLLA_CLIENT_SECRET']) do |config|

    config.environment = :sandbox
    # TODO
    # config.environment = :production
  end

  @@account_token = $dwolla.tokens.new(
    access_token: ENV['DWOLLA_ACCOUNT_ACCESS_TOKEN'],
    refresh_token: ENV['DWOLLA_ACCOUNT_REFRESH_TOKEN'],
    account_id: ENV['DWOLLA_ACCOUNT_ID']
  )

  def self.dev_get_customers
    ret = self.get('customers')
    ret['_embedded']['customers']
  end

  def self.dev_customer_exists(email)
    ret = self.get('customers?search=' + email)
    ret['_embedded']['customers'].size > 0 ? 'Yes' : 'No'
  end

  def self.add_customer(user, ssn, ip)
    return nil unless user && user.address && ssn && ip
    # Format phone number for Dwolla
    phone = user.number
    phone.slice! '+1' if phone.length == 12
    ret = self.post('customers', {
      firstName: user.fname,
      lastName: user.lname,
      email: user.email,
      phone: phone,
      ipAddress: ip,
      type: 'personal',
      address1: user.address.line1,
      address2: user.address.line2,
      city: user.address.city,
      state: user.address.state,
      postalCode: user.address.zip,
      dateOfBirth: user.dob.to_s,
      ssn: ssn
    }, {
      'Idempotency-Key': user.id.to_s
    })
    return ret unless ret['_embedded'] # Error, Dwolla should provide this key
    return ret['_embedded'] unless ret['_embedded']['errors']

    # Error
    if ret['_embedded']['errors'][0]['code'] == 'Duplicate'
      existing = self.get('customers?search=' + user.email)
      if existing['_embedded']['customers'].size > 0
        existing = existing['_embedded']['customers'][0]
        existing.delete('_links')
        return existing
      end
    end
    # No existing customer, forward the original error to the client
    ret['_embedded']
  end

  def self.get_funding_source(user)
    self.get('customers/' + user.dwolla_id + '/funding-sources')
  end

  def self.add_funding_source(user, account)
    self.post('customers/' + user.dwolla_id + '/funding-sources', {
      routingNumber: account.routing_num,
      accountNumber: account.account_num,
      type: 'checking', # TODO
      name: account.name
    }, {
      'Idempotency-Key': user.dwolla_id + account.account_num
    })
  end

  def self.transfer_money(customer_id, funding_source, amount)
    self.post("transfers", {
      _links: {
        destination: {
          href: 'https://api-uat.dwolla.com/customers/' + customer_id
          # TODO
          #href: 'https://api.dwolla.com/customers/' + customer_id
        },
        source: {
          href: 'https://api-uat.dwolla.com/funding-sources/' + funding_source
          # TODO
          #href: 'https://api.dwolla.com/funding-sources/' + funding_source
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
    }#, {
    #  'Idempotency-Key': user.id.to_s
    #}
    )
  end

  private

  def self.get(route)
    begin
      ret = @@account_token.get route
    rescue DwollaV2::NotFoundError => e
      return "ErrorNotFound"
    rescue DwollaV2::Error => e
      return e
    end
    ret
  end

  def self.post(route, payload, headers)
    begin
      ret = @@account_token.post route, payload, headers
    rescue DwollaV2::NotFoundError => e
      return "ErrorNotFound"
    rescue DwollaV2::Error => e
      return e
    end
    ret
  end
end
