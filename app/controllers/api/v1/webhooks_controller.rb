class Api::V1::WebhooksController < ApplicationController
  include WebhookHelper

  before_action :init
  # No webhooks require authentication

  def twilio
    logger.info "From:"
    logger.info params[:From]
    logger.info "Body:"
    logger.info params[:Body]
    head :ok
  end

  def plaid
    logger.info params
    head :ok
  end

  def dwolla
    logger.info params
    head :ok
  end
end
