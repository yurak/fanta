module NationalSquads
  # Pulls the called-up players out of the "Current squad" section of a Wikipedia article.
  #
  # Every rule here was paid for by a wrong answer:
  #
  #   * `{{nat fs r player}}` is the "Recent call-ups" table underneath — those players were NOT
  #     called up this time. Reading them as squad members once made Ireland look like a 66-man
  #     squad and buried the real changes.
  #   * `{{nat fs break}}` only splits the table into columns. Cutting there loses most of the squad.
  #     Only `nat fs end` / `nat fs g end` close it.
  #   * Articles mix `{{nat fs g player}}` and `{{Nat fs g player}}`, so tags match case-insensitively.
  #     A case-sensitive search dropped Dembélé and read it as a withdrawal.
  class WikiParser < ApplicationService
    PLAYER_TAGS = ['nat fs g player', 'nat fs player'].freeze
    END_MARKERS = ['nat fs end', 'nat fs g end'].freeze
    SECTION = 'current squad'.freeze
    BIRTH_DATE = /\{\{[Bb](?:irth date and age|da)[^}]*?\|(?:df=[yn]\|)?(\d{4})\|(\d{1,2})\|(\d{1,2})/
    SCAN_LIMIT = 20_000
    OPENERS = ['{{', '[['].freeze
    CLOSERS = ['}}', ']]'].freeze

    attr_reader :wikitext

    def initialize(wikitext)
      @wikitext = wikitext.to_s
    end

    # [{ name:, position:, club:, birth_date: }], empty when the article has no squad section
    def call
      return [] if section.blank?

      PLAYER_TAGS.flat_map { |tag| players_from(tag) }
    end

    private

    def section
      @section ||= begin
        start = wikitext.downcase.index(SECTION)
        start ? cut_at_end_marker(wikitext[start..]) : ''
      end
    end

    def cut_at_end_marker(text)
      ends = END_MARKERS.filter_map { |marker| text.downcase.index(marker) }.reject(&:zero?)

      ends.any? ? text[0...ends.min] : text[0, SCAN_LIMIT]
    end

    def players_from(tag)
      templates(section, tag).filter_map do |body|
        params = params_of(body)
        next if params['name'].blank?

        { name: clean(params['name']), position: params['pos'].to_s,
          club: clean(params['club'].to_s), birth_date: birth_date_of(params['age'].to_s) }
      end
    end

    # Every {{tag …}} body in the text, brace-balanced so nested templates survive intact.
    def templates(text, tag)
      found = []
      lowered = text.downcase
      opener = "{{#{tag}"
      cursor = 0

      while (start = lowered.index(opener, cursor))
        finish = closing_brace(text, start)
        found << text[(start + 2 + tag.length)...(finish - 2)]
        cursor = finish
      end

      found
    end

    def closing_brace(text, start)
      depth = 0
      cursor = start

      while cursor < text.length
        if text[cursor, 2] == '{{'
          depth += 1
          cursor += 2
        elsif text[cursor, 2] == '}}'
          depth -= 1
          cursor += 2
          return cursor if depth.zero?
        else
          cursor += 1
        end
      end

      cursor
    end

    def params_of(body)
      top_level_parts(body).filter_map { |part| part.split('=', 2) if part.include?('=') }
                           .to_h { |key, value| [key.strip, value.strip] }
    end

    def top_level_parts(body)
      state = { parts: [], depth: 0, current: +'', cursor: 0 }

      state[:cursor] = step(body, state) while state[:cursor] < body.length

      state[:parts] << state[:current]
    end

    def step(body, state)
      pair = body[state[:cursor], 2]
      return open_group(pair, state) if OPENERS.include?(pair)
      return close_group(pair, state) if CLOSERS.include?(pair)

      if body[state[:cursor]] == '|' && state[:depth].zero?
        state[:parts] << state[:current]
        state[:current] = +''
      else
        state[:current] << body[state[:cursor]]
      end

      state[:cursor] + 1
    end

    def open_group(pair, state)
      state[:depth] += 1
      state[:current] << pair

      state[:cursor] + 2
    end

    def close_group(pair, state)
      state[:depth] -= 1
      state[:current] << pair

      state[:cursor] + 2
    end

    def clean(value)
      value = value.gsub(%r{<ref.*?(/>|</ref>)}m, '')
                   .gsub(/\{\{efn[^{}]*\}\}/i, '')
                   .gsub(/\[\[([^|\]]*\|)?/, '').delete(']')
                   .gsub(/\{\{[^{}]*\}\}/, '')
                   .gsub(/\s*\(.*?\)/, '')

      value.squish
    end

    def birth_date_of(value)
      match = value.match(BIRTH_DATE)
      return '' unless match

      format('%<year>s-%<month>02d-%<day>02d', year: match[1], month: match[2].to_i, day: match[3].to_i)
    end
  end
end
