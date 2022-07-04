class ApplicationMailer < ActionMailer::Base
  default from: ENV['GMAIL_USERNAME'] || 'from@example.com'
  layout 'mailer'
end
