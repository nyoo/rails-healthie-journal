class Provider < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :clients, through: :enrollments
  has_many :journal_entries, -> { distinct }, through: :clients

  validates :name, :email, presence: true
end
