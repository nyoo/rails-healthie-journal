module ApplicationHelper
  def format_timestamp(value)
    value ? value.to_fs(:long) : "—"
  end

  def account_status(participant)
    participant.active? ? "Active" : "Inactive"
  end
end
