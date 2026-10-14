class JournalEntry < ApplicationRecord
  belongs_to :client

  scope :chronological, -> { order(created_at: :asc, id: :asc) }

  validates :content, presence: true
end
