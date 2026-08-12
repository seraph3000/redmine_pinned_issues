module IssuePatch
  def self.prepended(base)
    base.class_eval do
      has_one :pinned_issue, dependent: :destroy
      has_many :pinned_journals, dependent: :destroy
      has_one :active_pinned_issue,
              -> { where('expires_at IS NULL OR expires_at > ?', Time.current) },
              class_name: 'PinnedIssue',
              foreign_key: 'issue_id'
    end
  end

  def pinned?
    active_pinned_issue.present?
  end

  def css_classes(user=User.current)
    s = super(user)
    s = "#{s} pinned" if pinned?
    s
  end

  def visible_journals_with_index(user = User.current)
    @vjwi_cache ||= {}
    @vjwi_cache[user.id] ||= super
  end
end

Issue.prepend(IssuePatch) unless Issue.ancestors.include?(IssuePatch)