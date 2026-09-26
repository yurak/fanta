# frozen_string_literal: true

# Without an explicit lifetime the session cookie is a browser-session cookie, and on mobile the OS
# discards the browser under memory pressure all the time. The tab comes back from cache with the
# CSRF token of a session that no longer exists, the next submit dies with
# ActionController::InvalidAuthenticityToken, and a half-built lineup is lost with it.
#
# Two weeks matches `config.remember_for` in the Devise initializer, so the session and the
# remember-me cookie expire together instead of one outliving the other.
#
# The key stays `_fanta_session` — the Rails default this app has always used. Changing it would
# sign every user out.
Rails.application.config.session_store :cookie_store,
                                       key: '_fanta_session',
                                       expire_after: 2.weeks
