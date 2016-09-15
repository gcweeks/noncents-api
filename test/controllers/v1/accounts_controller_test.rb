require 'test_helper'

class V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/accounts/'
  end
end
