class Client < ApplicationRecord
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :providers, through: :enrollments
  has_many :journal_entries, dependent: :restrict_with_exception

  scope :active, -> { where(deactivated_at: nil) }

  validates :name, :email, presence: true
end
