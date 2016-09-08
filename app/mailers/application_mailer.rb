class ApplicationMailer < ActionMailer::Base
  default from: "donotreply@noncents.co"
  layout 'mailer'
end
