module TelegramBot
  class Sender < ApplicationService
    MAX_ATTEMPTS = 3
    # Telegram hands out a few seconds for an ordinary burst; anything longer means the bot is
    # seriously flooding, and a broadcast cron must not be parked on one recipient for that long.
    MAX_RETRY_WAIT = 15
    RATE_LIMITED = /too many requests/i
    RETRY_AFTER = /retry after (\d+)/i

    def initialize(user, message, parse_mode: nil, disable_web_page_preview: false)
      @message = message
      @parse_mode = parse_mode
      @disable_web_page_preview = disable_web_page_preview
      @user_profile = user&.user_profile
    end

    def call
      return false unless @user_profile
      return false unless @user_profile.bot_enabled

      deliver
    end

    private

    def deliver(attempt = 1)
      Telegram.bots[:default].send_message(**message_params)
      true
    rescue Telegram::Bot::Forbidden => e
      disable_bot(e)
      false
    rescue Telegram::Bot::Error => e
      return wait_and_retry(e, attempt) if retriable?(e, attempt)

      report(e)
      false
    end

    # A rate limit arrives as a plain error — the gem drops Telegram's `retry_after` parameter and
    # keeps only the description — so it is recognised by that text. Sleeping here also paces the
    # broadcast loop that called us, which is exactly what the limit is asking for.
    def retriable?(error, attempt)
      attempt < MAX_ATTEMPTS && error.message.match?(RATE_LIMITED) && retry_wait(error) <= MAX_RETRY_WAIT
    end

    def wait_and_retry(error, attempt)
      wait = retry_wait(error)
      Rails.logger.info("[telegram] rate limited for user #{@user_profile.user_id}, retrying in #{wait}s")
      Kernel.sleep(wait)
      deliver(attempt + 1)
    end

    def retry_wait(error)
      [error.message[RETRY_AFTER, 1].to_i, 1].max
    end

    def disable_bot(error)
      @user_profile.update(bot_enabled: false)
      Rails.logger.info(
        "[telegram] bot disabled for user #{@user_profile.user_id}: #{error.class}: #{error.message}"
      )
    end

    def report(error)
      Rollbar.error(error, user_id: @user_profile.user_id, chat_id: @user_profile.tg_chat_id,
                           parse_mode: @parse_mode, text: @message.to_s.truncate(300))
      Rails.logger.warn(
        "[telegram] send failed for user #{@user_profile.user_id}: #{error.class}: #{error.message}"
      )
    end

    def message_params
      params = { chat_id: @user_profile.tg_chat_id, text: @message }
      params[:parse_mode] = @parse_mode if @parse_mode
      params[:disable_web_page_preview] = true if @disable_web_page_preview
      params
    end
  end
end
