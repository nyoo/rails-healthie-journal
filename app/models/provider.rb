class Provider < ApplicationRecord
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :clients, -> { distinct }, through: :enrollments
  has_many :journal_entries, -> { distinct }, through: :clients
  has_many :active_enrollments, -> { active }, class_name: "Enrollment"
  has_many :current_clients, through: :active_enrollments, source: :client
  has_many :current_client_journal_entries, through: :current_clients,
    source: :journal_entries

  scope :active, -> { where(deactivated_at: nil) }

  validates :name, :email, presence: true

  def active?
    deactivated_at.nil?
  end
end
