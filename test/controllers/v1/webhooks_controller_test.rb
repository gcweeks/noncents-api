require 'test_helper'

class V1::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/webhooks/'
  end
end
