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

  @@url = 'https://api-uat.dwolla.com/'
  # TODO if @@account_token.client.environment == :production
  # 'https://api.dwolla.com/'

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
    res = self.post('customers', {
      firstName: user.fname,
      lastName: user.lname,
      email: user.email,
      phone: user.phone,
      ipAddress: ip,
      type: 'personal',
      address1: user.address.line1,
      address2: user.address.line2,
      city: user.address.city,
      state: user.address.state,
      postalCode: user.address.zip,
      dateOfBirth: user.dob.to_s,
      ssn: ssn
    })

    if res.class == DwollaV2::Response
      res = res.headers['location']
      unless res.slice!(@@url + 'customers/')
        Rails.logger.warn 'DwollaHelper.add_customer - Couldn\'t slice'
        Rails.logger.warn res
        return nil
      end
      return res
    end

    unless res['_embedded']
      Rails.logger.warn 'DwollaHelper.add_customer - No _embedded field'
      Rails.logger.warn res
      return nil
    end

    return res['_embedded']['id'] unless res['_embedded']['errors']

    # Error
    if res['_embedded']['errors'][0]['code'] == 'Duplicate'
      existing = self.get('customers?search=' + user.email)
      if existing['_embedded']['customers'].size > 0
        existing = existing['_embedded']['customers'][0]
        existing.delete('_links')
        return existing['id']
      end
    end

    # No existing customer, log error
    Rails.logger.warn 'DwollaHelper.add_customer - Error'
    Rails.logger.warn res['_embedded']
    nil
  end

  def self.get_funding_source(user)
    self.get('customers/' + user.dwolla_id + '/funding-sources')
  end

  def self.add_funding_source(user, account)
    if ENV['RAILS_ENV'] == 'test'
      # Get existing funding source by name
      res = self.get_existing_funding_source(user, account)
      return res unless res == nil
      # If res is nil, no existing funding source was found, so fall-through to
      # creating one.
    end

    if user.dwolla_id.nil?
      Rails.logger.warn 'DwollaHelper.add_funding_source - Not Dwolla Authed'
      return nil
    end

    res = self.post('customers/' + user.dwolla_id + '/funding-sources', {
      routingNumber: account.routing_num,
      accountNumber: account.account_num,
      type: account.account_subtype,
      name: account.name
    })

    if res.class == DwollaV2::Error
      if res['code'] == 'DuplicateResource'
        res = res['message']
        unless res.slice! 'Bank already exists: id='
          Rails.logger.warn 'DwollaHelper.add_funding_source - Couldn\'t slice'
          Rails.logger.warn res
          return nil
        end
        return res
      end
      Rails.logger.warn 'DwollaHelper.add_funding_source - Error'
      Rails.logger.warn res
      return nil
    end

    if res.class == DwollaV2::Response
      res = res.headers['location']
      unless res.slice!(@@url + 'funding-sources/')
        Rails.logger.warn 'DwollaHelper.add_customer - Couldn\'t slice res'
        Rails.logger.warn res
        return nil
      end
      return res
    end

    Rails.logger.warn 'DwollaHelper.add_funding_source - Unknown error'
    Rails.logger.warn res
    nil
  end

  def self.remove_funding_sources(user)
    return true if ENV['RAILS_ENV'] == 'test'

    res = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless res.class == DwollaV2::Response
      Rails.logger.warn 'DwollaHelper.remove_funding_sources - Couldn\t get funding sources'
      Rails.logger.warn res
      return false
    end
    unless res['_embedded']
      Rails.logger.warn 'DwollaHelper.remove_funding_sources - No _embedded field'
      Rails.logger.warn res
      return false
    end

    # Gather Dwolla funding sources
    funding_source_ids = []
    if ret['_embedded']['funding-sources']
      ret['_embedded']['funding-sources'].each do |funding_source|
        # Only remove banks that have not already been removed
        if funding_source['removed'] != true && funding_source['type'] == 'bank'

          funding_source_ids.push funding_source['id']
        end
      end
    end

    # Remove each Dwolla funding source
    funding_source_ids.each do |funding_source_id|
      # Don't remove existing funding sources
      next if [user.source_account.id,
               user.deposit_account.id].include?(funding_source_id)

      res = self.post('funding-sources/' + funding_source_id, {
        :removed => true
      })
      unless res.status == 200
        Rails.logger.warn 'DwollaHelper.remove_funding_sources - Couldn\t remove'
        Rails.logger.warn res
        return false
      end
    end
    true
  end

  def self.get_balance_funding_source(user)
    res = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless res.class == DwollaV2::Response
      Rails.logger.warn 'DwollaHelper.get_balance_funding_source - Couldn\t get funding sources'
      Rails.logger.warn res
      return false
    end
    unless res['_embedded']
      Rails.logger.warn 'DwollaHelper.get_balance_funding_source - No _embedded field'
      Rails.logger.warn res
      return false
    end

    # Find Dwolla balance funding source
    if res['_embedded']['funding-sources']
      res['_embedded']['funding-sources'].each do |funding_source|
        return funding_source['id'] if funding_source['type'] == 'balance'
      end
    end

    # No balance funding source found
    nil
  end

  def self.transfer_money(balance, source, deposit, amount)
    return true if ENV['RAILS_ENV'] == 'test'

    # Perform Source->Balance transaction
    res = self.perform_transfer(source, balance, amount)
    return false if res.nil?

    # Wait for webhook indicating that transaction has cleared
    DwollaTransaction.create(dwolla_id: res,
                             balance: balance,
                             source: source,
                             deposit: deposit,
                             amount: amount)
    true
  end

  def self.perform_transfer(source, destination, amount)
    res = self.post('transfers', {
      _links: {
        destination: {
          href: @@url + 'funding-sources/' + destination
        },
        source: {
          href: @@url + 'funding-sources/' + source
        }
      },
      amount: {
        currency: 'USD',
        value: '1.00'
      }#,
      #metadata: {
      #  foo: 'bar',
      #  baz: 'boo'
      #}
    }#, {
    #  'Idempotency-Key': '1234'
    #}
    )

    unless res && res.status == 201
      Rails.logger.warn 'DwollaHelper.perform_transfer - Error'
      Rails.logger.warn res
      return nil
    end

    res = res.headers['location']
    return nil unless res && res.slice!(@@url + 'transfers/')
    res
  end

  private

  def self.get_existing_funding_source(user, account)
    res = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless res.class == DwollaV2::Response
      Rails.logger.warn 'DwollaHelper.get_existing_funding_source - Couldn\t get funding sources'
      Rails.logger.warn res
      return nil
    end
    unless res['_embedded']
      Rails.logger.warn 'DwollaHelper.get_existing_funding_source - No _embedded field'
      Rails.logger.warn res
      return nil
    end

    # Find existing Dwolla funding source matching account name
    if res['_embedded']['funding-sources']
      res['_embedded']['funding-sources'].each do |funding_source|
        if funding_source['removed'] == false &&
           funding_source['name'] == account.name

          return funding_source['id']
        end
      end
    end

    nil
  end

  def self.get(route)
    begin
      ret = @@account_token.get route
    rescue DwollaV2::NotFoundError => e
      return 'ErrorNotFound'
    rescue DwollaV2::Error => e
      return e
    end
    ret
  end

  def self.post(route, payload, headers = nil)
    begin
      ret = @@account_token.post route, payload, headers
    rescue DwollaV2::NotFoundError => e
      return 'ErrorNotFound'
    rescue DwollaV2::Error => e
      return e
    end
    ret
  end
end
