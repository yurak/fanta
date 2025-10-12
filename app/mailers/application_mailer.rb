class ApplicationMailer < ActionMailer::Base
  default from: "Mantra Football <#{ENV.fetch('GMAIL_USERNAME', 'from@example.com')}>"
  layout 'mailer'
end
