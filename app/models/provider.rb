class Provider < ApplicationRecord
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :clients, through: :enrollments
  has_many :journal_entries, -> { distinct }, through: :clients

  scope :active, -> { where(deactivated_at: nil) }

  validates :name, :email, presence: true
end
