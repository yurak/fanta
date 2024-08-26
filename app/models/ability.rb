# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user&.admin?
      can :access, :rails_admin       # only allow admin users to access Rails Admin
      can :read, :dashboard           # allow access to dashboard
      can :manage, :all               # allow admins to do anything
    elsif user&.moderator?
      can %i[show], Auction
      can %i[update], MatchPlayer
      can %i[inject_scores], Tour
      can %i[edit update show auto_subs generate_preview], TournamentRound
      can %i[create destroy], Transfer
      can %i[new create destroy], Substitute
    end
  end
end
