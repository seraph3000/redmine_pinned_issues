module JournalPatch
  def self.prepended(base)
    base.class_eval do
      has_one :pinned_journal, dependent: :destroy
    end
  end

  # このコメントが重要登録されているか
  def important?
    pinned_journal.present?
  end

  # 誰が重要化したか（表示・ツールチップ用）
  def pinned_by
    pinned_journal&.user
  end

  # いつ重要化したか
  def pinned_at
    pinned_journal&.created_at
  end

  def css_classes
    classes = defined?(super) ? super.to_s : 'journal'
    classes += ' important-note-row' if important?
    classes
  end
end

Journal.prepend(JournalPatch) unless Journal.ancestors.include?(JournalPatch)