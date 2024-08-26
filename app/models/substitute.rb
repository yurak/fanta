class Substitute < ApplicationRecord
  belongs_to :main_mp, class_name: 'MatchPlayer'
  belongs_to :reserve_mp, class_name: 'MatchPlayer'
  belongs_to :in_rp, class_name: 'RoundPlayer'
  belongs_to :out_rp, class_name: 'RoundPlayer'
end
