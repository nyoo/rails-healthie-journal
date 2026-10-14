class Provider < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :clients, through: :enrollments

  validates :name, :email, presence: true
end
