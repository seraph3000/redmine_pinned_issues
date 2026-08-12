class PinnedJournal < ActiveRecord::Base
  belongs_to :journal
  belongs_to :issue
  belongs_to :project
  belongs_to :user

  validates :journal_id, presence: true, uniqueness: true
  validates :issue_id,   presence: true
  validates :project_id, presence: true
  validates :user_id,    presence: true
end