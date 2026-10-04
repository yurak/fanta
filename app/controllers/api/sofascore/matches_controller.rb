module Api
  module Sofascore
    class MatchesController < Api::ApplicationController
      skip_before_action :authenticate_user!
      skip_forgery_protection

      before_action :authenticate_ingest!

      def index
        sofascore_ids = TournamentMatch.where(tournament_round_id: params[:tournament_round_id])
                                       .where.not(source_match_id: [nil, ''])
                                       .pluck(:source_match_id)

        render json: { data: sofascore_ids }
      end

      def create
        match = TournamentMatch.find_by(source_match_id: params[:sofascore_id].to_s.presence)
        return render(json: { error: 'match_not_found' }, status: :not_found) unless match

        match.update!(base_data: params[:base_data], lineups_data: params[:lineups_data], incidents_data: params[:incidents_data])
        Scores::Injectors::SofascoreMatch.call(match)

        render json: { status: 'ok', tournament_match_id: match.id }
      end

      private

      def authenticate_ingest!
        return if valid_token?

        render json: { error: 'unauthorized' }, status: :unauthorized
      end

      def valid_token?
        expected = ingest_token
        expected.present? &&
          ActiveSupport::SecurityUtils.secure_compare(request.headers['X-Ingest-Token'].to_s, expected)
      end

      def ingest_token
        Rails.application.credentials.sofascore_ingest_token.presence ||
          ENV['SOFASCORE_INGEST_TOKEN'].presence
      end
    end
  end
end
