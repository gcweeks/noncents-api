class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Welcome to Noncents 🎉')
  end

  def welcome_need_info(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Additional Information Needed')
  end

  def transfer_notification(user)
    @user = user
    @amount = 100.25
    @source = 'Bank of America Checking'
    @deposit = 'Bank of America Savings'
    d = Time.zone.today + 1
    @date = d.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Notification')
  end

  def transfer_complete(user)
    @user = user
    @amount = 100.25
    @source = 'Bank of America Checking'
    @deposit = 'Bank of America Savings'
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Completed 💸')
  end

  def transfer_cancelled(user)
    @user = user
    @amount = 100.25
    @source = 'Bank of America Checking'
    @deposit = 'Bank of America Savings'
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Cancelled')
  end

  def transfer_failed(user)
    @user = user
    @amount = 100.25
    @source = 'Bank of America Checking'
    @deposit = 'Bank of America Savings'
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Failed')
  end

  def funding_added(user)
    @user = user
    @source = 'Bank of America Checking'
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Added a Funding Source 💵 ➡ 🏦')
  end

  def funding_removed(user)
    @user = user
    @source = 'Bank of America Checking'
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Removed a Funding Source')
  end

  def documents_needed(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Documents Needed')
  end

  def documents_uploaded(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Document Uploaded')
  end

  def documents_approved(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Document Approved ✅')
  end

  def documents_rejected(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Document Rejected')
  end

  def verification(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Account Verified 🎉')
  end

  def account_suspended(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Account Suspended')
  end

end
