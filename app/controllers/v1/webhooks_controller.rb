class V1::WebhooksController < ApplicationController
  include WebhookHelper
  include DwollaHelper
  include SlackHelper
  include UserHelper

  before_action :init
  # No webhooks require authentication

  def twilio
    logger.info "From:"
    logger.info params[:From]
    logger.info "Body:"
    logger.info params[:Body]
    SlackHelper.log("Twilio:\n```" + params.inspect + '```')
    head :ok
  end

  def plaid
    # TODO: Implement
    logger.info params
    head :ok
  end

  def dwolla
    response_hash = {
      'customer_created' => :customer_created,
      'customer_verification_document_needed' => :verification_document_needed,
      'customer_verification_document_uploaded' => :verification_document_uploaded,
      'customer_verification_document_failed' => :verification_document_failed,
      'customer_verification_document_approved' => :verification_document_approved,
      'customer_reverification_needed' => :reverification_needed,
      'customer_verified' => :customer_verified,
      'customer_suspended' => :customer_suspended,
      'customer_activated' => :customer_verified,
      'customer_funding_source_added' => :funding_source_added,
      'customer_funding_source_removed' => :funding_source_removed,
      'customer_funding_source_unverified' => :funding_source_unverified,
      'customer_funding_source_verified' => :funding_source_verified,
      'customer_transfer_created' => :transfer_created,
      'customer_bank_transfer_created' => :transfer_created,
      'customer_transfer_cancelled' => :transfer_cancelled,
      'customer_bank_transfer_cancelled' => :transfer_cancelled,
      'customer_transfer_failed' => :transfer_failed,
      'customer_bank_transfer_failed' => :transfer_failed,
      'customer_transfer_completed' => :transfer_completed,
      'customer_bank_transfer_completed' => :transfer_completed
    }
    return head :ok unless response_hash.key? params[:topic]
    dwolla_id = params[:_links][:customer][:href]
    dwolla_id.slice!(@@url + 'customers/')
    if dwolla_id.nil?
      # Log error
      error = 'Dwolla ID in webhook: ' + params[:topic] + ' - is nil'
      logger.warn error
      SlackHelper.log(error + "\n```" + params.inspect + '```')
      # Don't retry webhook
      return head :ok
    end

    @webhook_user = User.find_by(dwolla_id: dwolla_id)
    if @webhook_user.nil?
      # Log error
      error = 'Cannot find user via dwolla_id - ' + dwolla_id
      logger.warn error
      SlackHelper.log(error + "\n```" + params.inspect + '```')
      # Don't retry webhook
      return head :ok
    end

    send(response_hash[params[:topic]])
  end
end

def customer_created
  UserMailer.welcome_email(@webhook_user).deliver_now

  head :ok
end

def customer_verified
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.verification(user)
end

def customer_suspended
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.account_suspended(user)
end

def verification_document_needed
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.documents_needed(user)
end

def verification_document_uploaded
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.documents_uploaded(user)
end

def verification_document_approved
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.documents_approved(user)
end

def verification_document_failed
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.documents_rejected(user)
end

def funding_source_added
  # user = User.find_by(dwolla_id: params[:id])
  # UserMailer.funding_added(user)
end

def funding_source_unverified
  # user = User.find_by(dwolla_id: params[:id])
  # UserMailer.funding_removed(user)
end

def funding_source_removed
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.funding_removed(user)
end

def funding_source_verified
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.funding_added(user)
end

def transfer_created
  transaction_id = params[:resourceId]
  if transaction_id.nil?
    # Log error
    error = 'Webhook ' + params[:topic] + ' nil resourceId'
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
    return head :ok
  end

  # find user by Dwolla ID and send out notification
  transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)
  UserMailer.transfer_notification(@webhook_user,
                                   @webhook_user.source_account.name,
                                   @webhook_user.deposit_account.name,
                                   transaction.amount).deliver_now
  head :ok
end

def transfer_cancelled
  transaction_id = params[:resourceId]
  transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)

  user = User.find_by(dwolla_id: params[:id])
  UserMailer.transfer_cancelled(user,
                                user.source_account.name,
                                user.deposit_account.name,
                                transaction.amount)
end

def transfer_failed
  transaction_id = params[:resourceId]
  transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)

  user = User.find_by(dwolla_id: params[:id])
  UserMailer.transfer_failed(user,
                             user.source_account.name,
                             user.deposit_account.name,
                             transaction.amount)
end

def transfer_completed
  transaction_id = params[:resourceId]
  if transaction_id.nil?
    # Log error
    error = 'Webhook customer_bank_transfer_completed - nil resourceId'
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
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
  # Use dwolla ID in webhook to lookup user account
  user = User.find_by(dwolla_id: params[:id])
  UserMailer.transfer_complete(user,
                               user.source_account.name,
                               user.deposit_account.name,
                               transaction.amount)
  # TODO: Handle res, which should be a Dwolla transaction ID.
  logger.info res
  SlackHelper.log("Completed Dwolla webhook transaction.\n```" + res.inspect + '```')

  head :ok
end
