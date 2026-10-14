class JournalEntry < ApplicationRecord
  belongs_to :client

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  validates :content, presence: true
end
