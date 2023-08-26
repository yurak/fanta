# module TournamentMatches
#   class SerieaGenerator < ApplicationService
#     def call
#       tournament_rounds.each do |t_round|
#         round_data = TournamentRounds::SerieaEventsParser.call(t_round)
#         (1...round_data.length).step(2).each do |index|
#           match = round_data[index]
#           TournamentMatch.find_or_create_by(
#             tournament_round: t_round,
#             host_club: club(match.css('.home-team-name').children.text),
#             guest_club: club(match.css('.away-team-name').children.text)
#           )
#         end
#       end
#     end
#
#     private
#
#     def club(name)
#       Club.find_by(name: name) || Club.find_by(full_name: name)
#     end
#
#     def tournament_rounds
#       TournamentRound.where(season: season, tournament: tournament)
#     end
#
#     def tournament
#       @tournament ||= Tournament.find_by(code: Scores::Injectors::Strategy::ITALY)
#     end
#
#     def season
#       @season ||= Season.last
#     end
#   end
# end
