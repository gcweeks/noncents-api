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
    # No action currently needed for Plaid webhooks
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
    if params[:_links] && params[:_links][:customer]
      dwolla_id = params[:_links][:customer][:href]
    end
    dwolla_id.slice!(@@url + 'customers/') if dwolla_id
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

    @dwolla_url = @@url
    text = "Sent `"+params[:topic]+
      "` email to "+@webhook_user.fname+" "+@webhook_user.lname
    logger.info text
    SlackHelper.log(text)
    head :ok
    # send(response_hash[params[:topic]])
  end
end

def customer_created
  return head :ok unless @webhook_user.dwolla_status != 'verified'
  UserMailer.welcome_need_info(@webhook_user).deliver_now

  head :ok
end

def customer_verified
  dt = DateTime.parse params[:timestamp]
  time = @webhook_user.dwolla_verified_at

  # if the verification webhook comes in over an hour later, send
  # seperate verification email, not combined with welcome email
  if time && (time.utc + 1.hour > dt)
    UserMailer.verification(@webhook_user).deliver_now
  else
    UserMailer.welcome_email(@webhook_user).deliver_now
  end

  @webhook_user.dwolla_status = 'verified'
  @webhook_user.save!

  head :ok
end

def customer_suspended
  @webhook_user.dwolla_status = 'suspended'
  @webhook_user.save!
  UserMailer.account_suspended(@webhook_user).deliver_now

  head :ok
end

def reverification_needed
  @webhook_user.dwolla_status = 'retry'
  @webhook_user.save!

  head :ok
end

def verification_document_needed
  @webhook_user.dwolla_status = 'document'
  @webhook_user.save!

  UserMailer.documents_needed(@webhook_user).deliver_now

  head :ok
end

def verification_document_uploaded
  UserMailer.documents_uploaded(@webhook_user).deliver_now

  head :ok
end

def verification_document_approved
  @webhook_user.dwolla_status = 'verified'
  @webhook_user.save!

  UserMailer.documents_approved(@webhook_user).deliver_now

  head :ok
end

def verification_document_failed
  UserMailer.documents_rejected(@webhook_user).deliver_now

  head :ok
end

def funding_source_added
  # funding sources are verfied as they're linked through plaid
  head :ok
end

def funding_source_unverified
  head :ok
end

def funding_source_removed
  funding_source = params[:_links][:resource][:href]
  funding_source.slice!(@dwolla_url + 'funding-sources/')
  acct = Account.find_by(dwolla_id: funding_source)
  if acct.nil?
    # Log error
    error = params[:topic] + '- Cannot find source_account that was removed with dwolla_id - ' + funding_source
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
    return head :ok
  end

  UserMailer.funding_removed(@webhook_user, acct).deliver_now

  head :ok
end

def funding_source_verified
  funding_source = params[:_links][:resource][:href]
  funding_source.slice!(@dwolla_url + 'funding-sources/')
  acct = Account.find_by(dwolla_id: funding_source)
  if acct.nil?
    # Log error
    error = params[:topic] + '- Cannot find source_account that was verified with dwolla_id - ' + funding_source
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
    return head :ok
  end

  # don't notify if it was a deposit account that was added
  if acct.dwolla_id == @webhook_user.source_account.dwolla_id
    UserMailer.funding_added(@webhook_user, acct).deliver_now
  end

  head :ok
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
  if transaction_id.nil?
    # Log error
    error = 'Webhook ' + params[:topic] + ' nil resourceId'
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
    return head :ok
  end

  transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)
  UserMailer.transfer_cancelled(@webhook_user,
                                @webhook_user.source_account.name,
                                @webhook_user.deposit_account.name,
                                transaction.amount).deliver_now

  head :ok
end

def transfer_failed
  transaction_id = params[:resourceId]
  if transaction_id.nil?
    # Log error
    error = 'Webhook ' + params[:topic] + ' nil resourceId'
    logger.warn error
    SlackHelper.log(error + "\n```" + params.inspect + '```')
    # Don't retry webhook
    return head :ok
  end

  transaction = DwollaTransaction.find_by(dwolla_id: transaction_id)
  UserMailer.transfer_failed(@webhook_user,
                             @webhook_user.source_account.name,
                             @webhook_user.deposit_account.name,
                             transaction.amount).deliver_now

  head :ok
end

def transfer_completed
  transaction_id = params[:resourceId]
  if transaction_id.nil?
    # Log error
    error = 'Webhook ' + params[:topic] + ' nil resourceId'
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
  UserMailer.transfer_complete(@webhook_user,
                               @webhook_user.source_account.name,
                               @webhook_user.deposit_account.name,
                               transaction.amount).deliver_now
  # TODO: Handle res, which should be a Dwolla transaction ID.
  logger.info res
  SlackHelper.log("Completed Dwolla webhook transaction.\n```" + res.inspect + '```')

  head :ok
end
