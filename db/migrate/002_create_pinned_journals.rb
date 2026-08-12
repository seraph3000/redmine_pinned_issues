class CreatePinnedJournals < ActiveRecord::Migration[6.1]
  def change
    create_table :pinned_journals do |t|
      t.references :journal, null: false, foreign_key: true, index: { unique: true }
      t.references :issue,   null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.timestamps
    end
  end
end