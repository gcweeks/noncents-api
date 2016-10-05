class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Welcome to noncents 🎉')
  end

  def verification(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Account Verified 🎉')
  end

  def password_reset(user, code)
    @user = user
    @code = code
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Password Reset')
  end

  def welcome_need_info(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Additional Information Needed')
  end

  def transfer_notification(user, from, to, amount)
    @user = user
    @amount = amount
    @source = from
    @source_institution = user.source_account.institution
    @deposit = to
    @deposit_institution = user.deposit_account.institution
    d = Time.zone.today + 1
    @date = d.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Notification')
  end

  def transfer_complete(user, from, to, amount)
    @user = user
    @amount = amount
    @source = from
    @source_institution = user.source_account.institution
    @deposit = to
    @deposit_institution = user.deposit_account.institution
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Completed 💸')
  end

  def transfer_cancelled(user, from, to, amount)
    @user = user
    @amount = amount
    @source = from
    @source_institution = user.source_account.institution
    @deposit = to
    @deposit_institution = user.deposit_account.institution
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Cancelled')
  end

  def transfer_failed(user, from, to, amount)
    @user = user
    @amount = amount
    @source = from
    @source_institution = user.source_account.institution
    @deposit = to
    @deposit_institution = user.deposit_account.institution
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Transfer Failed')
  end

  def funding_added(user, funding_source)
    @user = user
    @institution = funding_source.institution
    @source = funding_source.name
    @date = DateTime.now.strftime("%B %d")
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Added a Funding Source 💵 ➡ 🏦')
  end

  def funding_removed(user, funding_source)
    @user = user
    @institution = funding_source.institution
    @source = funding_source.name
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

  def account_suspended(user)
    @user = user
    attachments.inline['logo.png'] = File.read('./app/assets/images/logo.png')
    attachments.inline['divider.png'] = File.read('./app/assets/images/divider.png')
    mail(to: @user.email, subject: 'Account Suspended')
  end
end
