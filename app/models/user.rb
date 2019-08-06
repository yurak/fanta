class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :team, dependent: :destroy

  EMAIL_LENGTH = (6..50).freeze
  ROLES = %w[customer admin].freeze

  enum role: ROLES

  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.a[a-z]+)*\.[a-z]+\z/i }, uniqueness: true
  validates :email, length: { in: EMAIL_LENGTH }
  validates :role, presence: true, inclusion: { in: ROLES }
end
