class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  enum :plan, { basic: "basic", premium: "premium" }, validate: true

  validates :plan, presence: true
  validates :client_id, uniqueness: { scope: :provider_id }
end
