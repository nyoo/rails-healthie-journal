class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  enum :plan, { basic: "basic", premium: "premium" }, validate: true

  attribute :started_at, default: -> { Time.current }

  scope :active, -> { where(ended_at: nil) }

  validates :plan, :started_at, presence: true
  validates :client_id, uniqueness: { scope: :provider_id, conditions: -> { active } }, if: :active?
  validate :end_not_before_start

  def active?
    ended_at.nil?
  end

  private

  def end_not_before_start
    if ended_at.present? && started_at.present? && ended_at < started_at
      errors.add(:ended_at, "cannot precede started_at")
    end
  end
end
