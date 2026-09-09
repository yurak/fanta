# frozen_string_literal: true

module TelegramBot
  # Messages that hide their URL behind a call to action have to be parsed by Telegram as HTML, and
  # then an unescaped `&` in a league or team name ("Bravery&Stupidity") is a 400 from the API — the
  # user simply never receives that notification. Escaping lives here so a notifier cannot forget it,
  # and so does the send, to keep the parse mode and the escaping in one place.
  module HtmlMessage
    PARSE_MODE = 'HTML'

    private

    # Only text is escaped: the url belongs inside the href rather than the visible text, and numbers
    # and formatted times carry nothing to escape.
    def html_message(key, locale:, **values)
      url = values.delete(:url)
      escaped = values.transform_values { |value| value.is_a?(String) ? CGI.escapeHTML(value) : value }
      escaped[:url] = url if url

      I18n.t(key, locale: locale, **escaped)
    end

    def send_html(user, text)
      TelegramBot::Sender.call(user, text, parse_mode: PARSE_MODE, disable_web_page_preview: true)
    end
  end
end
