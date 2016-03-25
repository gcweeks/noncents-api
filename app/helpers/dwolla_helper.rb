module DwollaHelper
  require 'dwolla_swagger'

  def init_dwolla
    DwollaSwagger::Swagger.configure do |config|
      config.access_token = 'GD31dPZjZji6GUM3GkHkuAmHfck0WGlW7o1Ql3oTV6lk8hexy1'
      config.host = 'api-uat.dwolla.com'
      config.base_path = '/'
    end
  end

  def dwolla_add_customer(user)
    init_dwolla
    jenny = DwollaSwagger::CreateCustomer.new
    jenny.first_name = user.fname
    jenny.last_name = user.lname
    jenny.email = user.email
    begin
      location = DwollaSwagger::CustomersApi.create(body: jenny)
    rescue DwollaSwagger::ClientError => _e
      # p eval(e.message)
      return { error: 400 }
    rescue DwollaSwagger::ServerError => _e
      # p eval(e.message)
      return { error: 500 }
    end
    { location: location }
  end

  def transfer_money
    dimention_account = 'AB443D36-3757-44C1-A1B4-29727FB3111C'
    source = '80275e83-1f9d-4bf7-8816-2ddcd5ffc197'
    transfer_request = {
      _links: {
        destination: {
          href: 'https://api-uat.dwolla.com/accounts/' + dimention_account
        },
        source: {
          href: 'https://api-uat.dwolla.com/funding-sources/' + source
        }
      },
      amount: { currency: 'USD', value: 225.00 }
    }

    xfer = DwollaSwagger::TransfersApi.create(body: transfer_request)
    xfer # => https://api-uat.dwolla.com/transfers/d76265cd-0951-e511-80da-0aa34a9b2388
  end
end
