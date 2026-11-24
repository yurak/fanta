# Which build is running. Two strings, answering different questions:
#
#   VERSION  — the human release number ("5.5.2"), bumped by hand in the release PR of the same
#              name. It is what we say out loud, and it drifts the moment someone forgets.
#   REVISION — the git SHA, written into every release directory by Capistrano
#              (capistrano/tasks/deploy.rake, `deploy:set_current_revision`). Nobody maintains it
#              by hand, so it is the one to trust, and it is what links a Rollbar stack frame to
#              the source on GitHub.
#
# Both are read once at boot, before Rails.root exists — hence __dir__. REVISION is absent outside
# a deployed release (development, CI, a bare checkout), and nil is the correct answer there.
module Fanta
  module Release
    ROOT = File.expand_path('..', __dir__)

    class << self
      def version
        @version ||= read('VERSION')
      end

      def revision
        @revision ||= read('REVISION')
      end

      def label
        [version, revision && "(#{revision[0, 7]})"].compact.join(' ').presence
      end

      private

      def read(name)
        path = File.join(ROOT, name)
        return nil unless File.exist?(path)

        content = File.read(path).strip
        content.empty? ? nil : content
      end
    end
  end
end
