class Api::V1::WebhooksController < ApplicationController
  include WebhookHelper
  include DwollaHelper

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
    # Only handle customer_bank_transfer_completed webhook for now
    return head :ok unless params[:topic] == 'customer_bank_transfer_completed'
    transaction_id = params[:resourceId]
    if transaction_id.nil?
      # TODO email error
      logger.warn "Webhook customer_bank_transfer_completed - nil resourceId"
      return head :ok
    end

    transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)
    # Balance->Savings transactions will come in all the time, and there is
    # no need to handle them, so there will not be a corresponding
    # DwollaTransaction model, so just return.
    return head :ok if transaction.nil?

    # Found a DwollaTransaction that needs to be finished.
    res = DwollaHelper.perform_transfer(transaction.balance,
                                        transaction.deposit,
                                        transaction.amount)
    # TODO Handle res, which should be a Dwolla transaction ID.
    logger.info "Completed Dwolla webhook transaction."
    logger.info res

    head :ok
  end
end
