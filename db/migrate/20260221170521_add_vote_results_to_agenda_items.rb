class AddVoteResultsToAgendaItems < ActiveRecord::Migration[8.1]
  def change
    add_column :agenda_items, :result, :string
    add_column :agenda_items, :vote_tally, :string
  end
end
