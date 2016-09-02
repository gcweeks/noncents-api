module DwollaHelper
  require 'dwolla_v2'

  $dwolla = DwollaV2::Client.new(
    id: ENV['DWOLLA_CLIENT_ID'],
    secret: ENV['DWOLLA_CLIENT_SECRET']) do |config|

    config.environment = :sandbox
    # TODO
    # config.environment = :production
    # Also change instances of api-uat
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
    ret = self.post('customers', {
      firstName: user.fname,
      lastName: user.lname,
      email: user.email,
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

  # TODO Unused. Necessary?
  def self.get_funding_sources(user)
    self.get('customers/' + user.dwolla_id + '/funding-sources')
  end

  def self.add_funding_source(user, account)
    return nil if account.dwolla_id != nil
    res = self.post('customers/' + user.dwolla_id + '/funding-sources', {
      routingNumber: account.routing_num,
      accountNumber: account.account_num,
      type: account.account_subtype,
      name: account.name
    }, {
      'Idempotency-Key': user.dwolla_id + account.account_num.to_s
    })

    funding_source = res.headers['location']
    # TODO: Check prod URL as well
    unless funding_source &&
           funding_source.slice!('https://api-uat.dwolla.com/funding-sources/')

      funding_source = res['message']
      if funding_source
        unless funding_source.slice!('Bank already exists: id=')
          funding_source = nil
        end
      end
    end

    if funding_source
      account.dwolla_id = funding_source
      account.save!
      return nil
    end

    res
  end

  def self.transfer(source_account, deposit_account, amount)
    p "Depositing " + amount.to_s
    p "Source: " + source_account.dwolla_id
    p "Deposit: " + deposit_account.dwolla_id
    res = self.post("transfers", {
      _links: {
        # TODO Production URL as well
        source: {
          href: 'https://api-uat.dwolla.com/funding-sources/' +
            source_account.dwolla_id
        },
        destination: {
          href: 'https://api-uat.dwolla.com/funding-sources/' +
            deposit_account.dwolla_id
        }
      },
      amount: {
        currency: 'USD',
        value: amount.to_s
      }
    }, {
      'Idempotency-Key': source_account.id.to_s + DateTime.current.to_s
    }
    )
    p res
    return nil
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
