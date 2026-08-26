module Manage
  class TournamentsController < BaseController
    def index
      @tournaments = Tournament.order(:id)
    end

    def edit
      @tournament = Tournament.find(params.expect(:id))
    end

    def update
      @tournament = Tournament.find(params.expect(:id))

      if @tournament.update(tournament_params)
        redirect_to manage_tournaments_path, notice: t('manage.tournaments.updated', name: @tournament.name)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tournament_params
      params.expect(tournament: %i[name short_name code icon source mode eurocup open_join
                                   skip_round_check live_scores_enabled source_calendar_url
                                   source_id sofa_number lineup_first_goal lineup_increment])
    end
  end
end
