class JournalEntriesController < ApplicationController
  def index
    @journal_entries = JournalEntry.includes(:client).recent_first
  end

  def show
    @journal_entry = JournalEntry.includes(:client).find(params[:id])
  end
end
