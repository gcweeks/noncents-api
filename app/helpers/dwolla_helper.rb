module DwollaHelper
  require 'dwolla_v2'
  include DwollaTokenConcern
  include SlackHelper

  @@url = 'https://api-uat.dwolla.com/'
  # TODO: if account_token.client.environment == :production
  # 'https://api.dwolla.com/'

  def self.add_customer(user, ssn, ip, retrying = false)
    return nil if user.blank? || user.address.blank? || ssn.blank? || ip.blank?
    payload = {
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
    }
    route = 'customers'
    if retrying
      if user.dwolla_id.blank?
        log_error('DwollaHelper.add_customer - Retrying without dwolla_id')
        return nil
      end
      route = route + '/' + user.dwolla_id
    end
    response = self.post(route, payload)

    if response.class == DwollaV2::Response
      ret = response.headers['location']
      unless ret && ret.slice!(@@url + 'customers/')
        log_error('DwollaHelper.add_customer - Couldn\'t slice', response)
        return nil
      end
      unless ret.class == String
        log_error('DwollaHelper.add_customer - Bad slice', response)
        return nil
      end
      # Success
      return ret
    elsif response.class == DwollaV2::ValidationError && !retrying
      # Possibly a duplicate, look in _embedded field
      errors = response['_embedded']['errors'] rescue nil
      if errors.blank? || !errors.is_a?(Array) || errors.length == 0
        log_error('DwollaHelper.add_customer - No embedded errors', response)
        return nil
      end
      errors.each do |error|
        if error['code'] == 'Duplicate'
          return self.get_existing_customer(user.email)
        end
      end
      # Some other validation error
    end

    # Unknown error
    if retrying
      log_error('DwollaHelper.add_customer - Error (retrying)', response)
    else
      log_error('DwollaHelper.add_customer - Error', response)
    end

    nil
  end

  def self.submit_document(user, file, type)
    return nil if user.blank? || file.blank? || type.blank?
    if user.dwolla_id.blank?
      log_error('DwollaHelper.submit_document - Submitting without dwolla_id')
      return nil
    end

    route = 'customers/' + user.dwolla_id + '/documents'
    response = self.post(route, file: file, documentType: type)

    if response.class == DwollaV2::Response
      ret = response.headers['location']
      unless ret && ret.slice!(@@url + 'documents/')
        log_error('DwollaHelper.submit_document - Couldn\'t slice', response)
        return nil
      end
      unless ret.class == String
        log_error('DwollaHelper.submit_document - Bad slice', response)
        return nil
      end
      # Success
      return ret
    else
      log_error('DwollaHelper.submit_document - Document failure', response)
      return nil
    end

    # Unknown error
    log_error('DwollaHelper.submit_document - Unknown error', response)

    nil
  end

  def self.get_customer_status(dwolla_id)
    response = self.get('customers/' + dwolla_id)

    unless response.class == DwollaV2::Response
      log_error('DwollaHelper.get_customer_status - Bad response', response)
      return nil
    end

    if response['status'].blank?
      log_error('DwollaHelper.get_customer_status - Unknown response', response)
      return nil
    end

    ret = response['status']
    unless ret.class == String
      log_error('DwollaHelper.add_customer - Bad slice', response)
      return nil
    end

    ret
  end

  def self.get_funding_source(user)
    self.get('customers/' + user.dwolla_id + '/funding-sources')
  end

  def self.add_funding_source(user, account)
    if ENV['RAILS_ENV'] == 'test'
      # Get existing funding source by name
      response = self.get_existing_funding_source(user, account)
      return response unless response == nil
      # If response is nil, no existing funding source was found, so fall-through to
      # creating one.
    end

    if user.dwolla_id.blank?
      log_error('DwollaHelper.add_funding_source - Not Dwolla Authed', response)
      return nil
    end

    route = 'customers/' + user.dwolla_id + '/funding-sources'
    payload = {
      routingNumber: account.routing_num,
      accountNumber: account.account_num,
      type: account.account_subtype,
      name: account.name
    }
    response = self.post(route, payload)

    if response.class == DwollaV2::Error
      if response['code'] == 'DuplicateResource'
        ret = response['message']
        unless ret && ret.slice!('Bank already exists: id=')
          log_error('DwollaHelper.add_funding_source - Couldn\'t slice', response)
          return nil
        end
        return ret
      end
      log_error('DwollaHelper.add_funding_source - Error', response)
      return nil
    end

    if response.class == DwollaV2::Response
      ret = response.headers['location']
      unless ret && ret.slice!(@@url + 'funding-sources/')
        log_error('DwollaHelper.add_customer - Couldn\'t slice ret', response)
        return nil
      end
      return ret
    end

    log_error('DwollaHelper.add_funding_source - Unknown error', response)

    nil
  end

  def self.remove_funding_sources(user)
    return false if user.dwolla_id.blank?

    return true if ENV['RAILS_ENV'] == 'test'

    response = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless response.class == DwollaV2::Response
      log_error("DwollaHelper.remove_funding_sources - Couldn't get funding sources", response)
      return false
    end
    unless response['_embedded']
      log_error('DwollaHelper.remove_funding_sources - No _embedded field', response)
      return false
    end

    # Gather Dwolla funding sources
    funding_source_ids = []
    if response['_embedded']['funding-sources']
      response['_embedded']['funding-sources'].each do |funding_source|
        # Only remove banks that have not already been removed
        if funding_source['removed'] != true && funding_source['type'] == 'bank'
          funding_source_ids.push funding_source['id']
        end
      end
    end

    # Remove each Dwolla funding source
    existing_sources = []
    existing_sources.push(user.source_account.id) if user.source_account
    existing_sources.push(user.deposit_account.id) if user.deposit_account
    funding_source_ids.each do |funding_source_id|
      # Don't remove existing funding sources
      next if existing_sources.include?(funding_source_id)

      payload = { :removed => true }
      response = self.post('funding-sources/' + funding_source_id, payload)
      unless response.status == 200
        log_error('DwollaHelper.remove_funding_sources - Couldn\t remove', response)
        return false
      end
    end

    true
  end

  def self.get_balance_funding_source(user)
    response = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless response.class == DwollaV2::Response
      log_error('DwollaHelper.get_balance_funding_source - Couldn\t get funding sources', response)
      return false
    end
    unless response['_embedded']
      log_error('DwollaHelper.get_balance_funding_source - No _embedded field', response)
      return false
    end

    # Find Dwolla balance funding source
    if response['_embedded']['funding-sources']
      response['_embedded']['funding-sources'].each do |funding_source|
        return funding_source['id'] if funding_source['type'] == 'balance'
      end
    end

    # No balance funding source found
    nil
  end

  def self.transfer_money(user, balance, amount)
    return false if user.blank? || balance.blank? || amount.blank?

    return true if ENV['RAILS_ENV'] == 'test'

    # Perform Source->Balance transaction
    source = user.source_account.dwolla_id
    deposit = user.deposit_account.dwolla_id
    response = self.perform_transfer(source, balance, amount)
    return false if response.blank?

    # Wait for webhook indicating that transaction has cleared
    dt = DwollaTransaction.new(dwolla_id: response,
                          balance: balance,
                          source: source,
                          deposit: deposit,
                          amount: amount)
    dt.user = user
    unless dt.save
      log_error('DwollaHelper.perform_transfer - Couldn\'t create DwollaTransaction', dt.errors)
      return false
    end

    true
  end

  def self.perform_transfer(source, destination, amount)
    payload = {
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
        value: amount
      }#,
      #metadata: {
      #  foo: 'bar',
      #  baz: 'boo'
      #}
    }#, {
    #  'Idempotency-Key': '1234'
    #}
    response = self.post('transfers', payload)

    unless response && response.status == 201
      log_error('DwollaHelper.perform_transfer - Error', response)
      return nil
    end

    ret = response.headers['location']
    unless ret && ret.slice!(@@url + 'transfers/')
      log_error('DwollaHelper.perform_transfer - Couldn\'t slice ret', response)
      return nil
    end

    ret
  end

  private

  def self.log_error(error, response = nil)
    Rails.logger.warn(error)
    if response.present?
      Rails.logger.warn(response)
      error = error + "\n```" + response.inspect + '```'
    end
    SlackHelper.log(error)
  end

  def self.get_existing_customer(email)
    response = self.get('customers?search=' + email)
    if response['_embedded']['customers'].size > 0
      ret = response['_embedded']['customers'][0]['id']
      unless ret.class == String
        log_error('DwollaHelper.add_customer - Bad duplicate id', response)
        return nil
      end
      return ret
    end

    nil
  end

  def self.get_existing_funding_source(user, account)
    response = self.get('customers/' + user.dwolla_id + '/funding-sources')
    unless response.class == DwollaV2::Response
      log_error('DwollaHelper.get_existing_funding_source - Couldn\t get funding sources', response)
      return nil
    end
    unless response['_embedded']
      log_error('DwollaHelper.get_existing_funding_source - No _embedded field', response)
      return nil
    end

    # Find existing Dwolla funding source matching account name
    if response['_embedded']['funding-sources']
      response['_embedded']['funding-sources'].each do |funding_source|
        if funding_source['removed'] == false &&
           funding_source['name'] == account.name

          return funding_source['id']
        end
      end
    end

    nil
  end

  def self.get(route)
    SlackHelper.log("```Access Token: "+account_token.access_token+
                    "\nRefresh Token: "+account_token.refresh_token+"```")
    begin
      response = account_token.get(route)
    rescue DwollaV2::Error => e
      return e
    end

    response
  end

  def self.post(route, payload, headers = nil)
    SlackHelper.log("```Access Token: "+account_token.access_token+
                    "\nRefresh Token: "+account_token.refresh_token+"```")
    begin
      response = account_token.post(route, payload, headers)
    rescue DwollaV2::Error => e
      return e
    end

    response
  end
end
