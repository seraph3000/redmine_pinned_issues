# plugins/redmine_pinned_issues/db/migrate/001_create_pinned_issues.rb

class CreatePinnedIssues < ActiveRecord::Migration[6.1]
  def change
    create_table :pinned_issues do |t|
      t.references :issue, null: false, foreign_key: true, index: { unique: true }
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: true
      t.timestamps
    end

    add_index :pinned_issues, :expires_at
  end
end
