module IssuePatch
  def self.prepended(base)
    base.class_eval do
      has_one :pinned_issue, dependent: :destroy
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
    # 無条件で 'patch-alive-test' というクラスをねじ込む
    "#{super(user)} patch-alive-test #{pinned? ? 'pinned' : ''}".strip
  end
end

Issue.prepend(IssuePatch) unless Issue.ancestors.include?(IssuePatch)