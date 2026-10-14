class Provider < ApplicationRecord
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :clients, through: :enrollments

  scope :active, -> { where(deactivated_at: nil) }

  validates :name, :email, presence: true
end
