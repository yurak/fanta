namespace :telegram do
  # rake telegram:set_commands
  #
  # Publishes the command menu Telegram shows beside the input box. Nothing routes through this:
  # the webhook answers a known command whether or not it is listed, so this only governs what the
  # user is offered. Telegram replaces the whole list on each call, hence every command every time.
  #
  # One call per language; Telegram picks by the client's own language and falls back to the list
  # sent without a language_code.
  desc "Publish the bot's command menu to Telegram"
  task set_commands: :environment do
    { nil => :en, 'uk' => :ua }.each do |language_code, locale|
      commands = Telegram::WebhookController::COMMAND_MENU.map do |command|
        { command: command, description: I18n.t("telegram.commands.#{command}", locale: locale) }
      end

      params = { commands: commands }
      params[:language_code] = language_code if language_code

      Telegram.bots[:default].set_my_commands(**params)
      puts "#{locale}: #{commands.map { |entry| entry[:command] }.join(', ')}"
    end

    puts 'Done.'
  end
end
