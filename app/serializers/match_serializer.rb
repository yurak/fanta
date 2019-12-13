class MatchSerializer < ActiveModel::Serializer
  attributes :id, :host, :host_goals, :host_score, :guest, :guest_goals, :guest_score
end
