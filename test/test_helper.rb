ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock'
include WebMock::API
WebMock.enable!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def fixture_json(name)
    JSON.parse(File.read('test/fixtures/files/' + name + '.json'))
  end

  def fixture(name)
    fixture_json(name).to_json
  end

  # Stubs

  def stub_dwolla(method, path, body: {}, query: {}, status: 200, response: nil, response_headers: nil, host: 'api-uat.dwolla.com')
    headers = {}
    headers['Accept'] = 'application/vnd.dwolla.v1.hal+json'

    expectations = {}
    expectations[:headers] = headers unless headers.empty?
    expectations[:body] = body unless body.empty?
    expectations[:query] = query unless query.empty?

    stub = stub_request(method, "https://#{host}/#{path}")
    stub = stub.with(expectations) unless expectations.empty?

    if response_headers
      response_headers = JSON.parse(response_headers)
    else
      response_headers = {}
    end
    response_headers['content-type'] = "application/vnd.dwolla.v1.hal+json; charset=UTF-8"

    stub.to_return(status: status, body: response, headers: response_headers)
  end

  def initialize_dwolla_stubs(user)
    initial_json = fixture_json('dwolla_add_customer')
    dwolla_id = initial_json['location'].clone
    dwolla_id.slice!('https://api-uat.dwolla.com/customers/')

    # Add Customer
    json = initial_json.to_json
    body = {
      firstName: user.fname,
      lastName: user.lname,
      email: user.email,
      phone: user.phone,
      ipAddress: '127.0.0.1',
      type: 'personal',
      address1: user.address.line1,
      address2: user.address.line2,
      city: user.address.city,
      state: user.address.state,
      postalCode: user.address.zip,
      dateOfBirth: user.dob.to_s,
      ssn: '123-45-6789'
    }
    stub_dwolla :post, 'customers', body: body, status: 201, response_headers: json
    # Add Customer (duplicate email)
    # json = fixture('dwolla_add_customer_existing_email')
    # stub_dwolla :post, 'customers', body: body, response: json

    # Get Customer status
    json = fixture('dwolla_get_customer_status')
    stub_dwolla :get, 'customers/'+dwolla_id, response: json

    # Get Funding Sources
    json = fixture('dwolla_get_funding_sources')
    stub_dwolla :get, 'customers/'+dwolla_id+'/funding-sources', response: json

    # Add Funding Sources
    json = fixture('dwolla_add_checking')
    body = {
      routingNumber:'021000021',
      accountNumber:'9900001702',
      type:'checking',
      name:'Plaid Checking'
    }
    stub_dwolla :post, 'customers/'+dwolla_id+'/funding-sources', body: body, status: 201, response_headers: json
    json = fixture('dwolla_add_savings')
    body = {
      routingNumber:'021000021',
      accountNumber:'9900009606',
      type:'savings',
      name:'Plaid Savings'
    }
    stub_dwolla :post, 'customers/'+dwolla_id+'/funding-sources', body: body, status: 201, response_headers: json

    # Remove funding source
    fs_json = fixture_json('dwolla_get_funding_sources')
    fs_json = fs_json['_embedded']['funding-sources']
    initial_json = fixture_json('dwolla_remove_funding_source')
    body = { removed: true }
    source_id = destination_id = nil
    fs_json.each do |fs|
      initial_json['_links']['self']['href'] = 'https://api-uat.dwolla.com/funding-sources/'+fs['id']
      initial_json['id'] = fs['id']
      initial_json['name'] = fs['name']
      if fs['name'] == 'Plaid Checking'
        source_id = fs['id']
      elsif fs['name'] == 'Plaid Savings'
        destination_id = fs['id']
      end
      json = initial_json.to_json
      stub_dwolla :post, 'funding-sources/'+fs['id'], response: json
    end
  end

  def stub_plaid(method, path, body: {}, query: {}, status: 200, response: nil, host: 'tartan.plaid.com')
    headers = {}
    if method != :get
      headers['Content-Type'] = 'application/x-www-form-urlencoded'
    end

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

  def initialize_plaid_stubs
    initialize_plaid_stubs_by_product('auth')
    initialize_plaid_stubs_by_product('connect')

    json = fixture('plaid_get')
    body = {
      access_token: 'test_chase',
      options: "{\"pending\":false}"
    }
    stub_plaid :post, 'connect/get', body: body, response: json
  end

  def initialize_plaid_stubs_by_product(product)
    # Plaid Add
    json = fixture('plaid_mfa_list')
    options = (product=='auth') ? "{\"list\":true}" : "{\"login_only\":true,\"list\":true}"
    body = {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'chase', # Code-based
      options: options
    }
    # Status of 201 required for it to be considered MFA
    stub_plaid :post, product, body: body, status: 201, response: json

    # Plaid MFA
    json = fixture('plaid_mfa_code_sent')
    body = {
      access_token: 'test_chase',
      options: "{\"send_method\":{\"type\":\"email\"}}"
    }
    stub_plaid :post, product+'/step', body: body, response: json
    body[:options] = "{\"send_method\":{\"mask\":\"xxx-xxx-5309\"}}"
    stub_plaid :post, product+'/step', body: body, response: json

    # Wrong MFA
    json = fixture('plaid_mfa_code_incorrect')
    options = (product=='auth') ? "{}" : "{\"login_only\":true}"
    body = {
      access_token: 'test_chase',
      mfa: 'wrong',
      options: options
    }
    stub_plaid :post, product+'/step', body: body, status: 402, response: json

    # No MFA
    json = fixture('plaid_' + product + '_add')
    options = (product=='auth') ? "{}" : "{\"login_only\":true}"
    body = {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'wells', # No MFA
      options: options
    }
    stub_plaid :post, product, body: body, response: json

    # Plaid Upgrade
    body = {
      access_token: 'test_chase',
      upgrade_to: product
    }
    stub_plaid :post, 'upgrade', body: body, response: json

    # Correct MFA
    json.sub! 'test_wells', 'test_chase'
    body = {
      access_token: 'test_chase',
      mfa: '1234',
      options: options
    }
    stub_plaid :post, product+'/step', body: body, response: json

    # MFA Questions
    json = fixture('plaid_mfa_questions')
    body = {
      username: 'plaid_test',
      password: 'plaid_good',
      type: 'bofa', # Questions
      options: options
    }
    # Status of 201 required for it to be considered MFA
    stub_plaid :post, product, body: body, status: 201, response: json
    body = {
      access_token: 'test_bofa',
      mfa: 'again',
      options: options
    }
    stub_plaid :post, product+'/step', body: body, status: 201, response: json
  end

  # Add more helper methods to be used by all tests here...
end
