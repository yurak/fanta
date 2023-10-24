# Setup listener for i18n https://github.com/fnando/i18n-js#using-listen
Rails.application.config.after_initialize do
  require "i18n-js/listen"
  I18nJS.listen
end