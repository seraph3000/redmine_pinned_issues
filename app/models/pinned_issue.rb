# plugins/redmine_pinned_issues/app/models/pinned_issue.rb

class PinnedIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :project
  belongs_to :user

  validates :issue_id, presence: true, uniqueness: true
  validates :project_id, presence: true
  validates :user_id, presence: true

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
end
