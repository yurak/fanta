module NationalSquads
  module SquadList
    DIR = Rails.root.join('config/mantra/national_squads').freeze

    module_function

    def path(name = nil)
      return DIR.join(name).to_s if name.present?

      Dir[DIR.join('*.csv')].grep_v(/missing/).max_by { |file| File.mtime(file) }
    end
  end
end
