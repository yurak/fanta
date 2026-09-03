module Manage
  class TournamentsController < BaseController
    def index
      @tournaments = Tournament.order(:id)
    end

    def show
      @tournament = Tournament.find(params.expect(:id))
      @clubs_count = @tournament.clubs.count
      @ec_clubs_count = @tournament.ec_clubs.count
      @national_teams_count = @tournament.national_teams.count
      @leagues_count = @tournament.leagues.count
      @active_leagues_count = @tournament.leagues.active.count
      @rounds_count = @tournament.tournament_rounds.count
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

    def create_rounds
      tournament = Tournament.find(params.expect(:id))
      count = params[:rounds_count].to_i

      if count.positive? && TournamentRounds::Creator.call(tournament.id, Season.last&.id, count)
        redirect_to manage_tournament_path(tournament), notice: t('manage.tournaments.rounds_created', count: count)
      else
        redirect_to manage_tournament_path(tournament), alert: t('manage.tournaments.rounds_failed')
      end
    end

    def import_calendar
      tournament = Tournament.find(params.expect(:id))
      result = TournamentMatches::CalendarImporter.call(tournament)

      redirect_to manage_tournament_path(tournament), import_flash(result)
    end

    private

    def import_flash(result)
      return { alert: t('manage.tournaments.calendar_empty') } if result[:created].zero? && result[:updated].zero?

      { notice: t('manage.tournaments.calendar_imported', **import_summary(result)) }
    end

    def import_summary(result)
      {
        created: result[:created], updated: result[:updated],
        skipped: skipped_note(result), unknown: unknown_note(result), failed: failed_note(result)
      }
    end

    def skipped_note(result)
      return '' if result[:skipped].zero?

      t('manage.tournaments.calendar_skipped', count: result[:skipped], rounds: result[:missing_rounds].join(', '))
    end

    def failed_note(result)
      return '' if result[:failed].zero?

      t('manage.tournaments.calendar_failed', count: result[:failed])
    end

    def unknown_note(result)
      return '' if result[:unknown_clubs].empty?

      t('manage.tournaments.calendar_unknown_clubs', clubs: result[:unknown_clubs].join(', '))
    end

    def tournament_params
      params.expect(tournament: %i[name short_name code icon source mode eurocup open_join
                                   skip_round_check live_scores_enabled source_calendar_url
                                   source_id sofa_number lineup_first_goal lineup_increment])
    end
  end
end
