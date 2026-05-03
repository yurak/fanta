class ApplicationMailer < ActionMailer::Base
  default from: "Mantra Football <#{ENV.fetch('MAILER_FROM', 'noreply@mantrafootball.org')}>"
  layout 'mailer'
end
