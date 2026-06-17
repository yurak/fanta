Telegram.bots_config = {
  default: Rails.application.credentials.dig(Rails.env.to_sym, :telegram, :bot)
}
