# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user&.admin?
      can :access, :rails_admin       # only allow admin users to access Rails Admin
      can :read, :dashboard           # allow access to dashboard
      can :manage, :all               # allow admins to do anything
    else
      cannot %i[new create edit update destroy], Article
    end
  end
end
