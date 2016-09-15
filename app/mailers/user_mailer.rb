class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    @url  = 'https://noncents.co/'
    mail(to: @user.email, subject: 'Welcome to Noncents')
  end
end
