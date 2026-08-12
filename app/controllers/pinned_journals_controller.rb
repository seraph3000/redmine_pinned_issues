class PinnedJournalsController < ApplicationController
  before_action :find_journal
  before_action :authorize_pin

  def toggle
    existing = PinnedJournal.find_by(journal_id: @journal.id)
    if existing
      unpin(existing)
      @important = false
    else
      pin
      @important = true
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def find_journal
    @journal = Journal.find(params[:journal_id])
    @issue   = @journal.journalized
    # journalized は polymorphic。Issue 以外や orphan で 500 にしない
    return render_404 unless @issue.is_a?(Issue)
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # 重要登録できるのは、そのコメントを実際に閲覧できて権限を持つ人だけ。
  def authorize_pin
    # 可視性を先に見ることで、403/404 の差による存在確認オラクルを潰す
    return render_403 unless @journal.visible?(User.current)
    return render_403 unless User.current.allowed_to?(:pin_journals, @project)
    # UI（journals_helper_patch）は notes ありのみボタンを出すので、サーバ側も揃える
    return render_403 if @journal.notes.blank?
    true
  end

  def pin
    PinnedJournal.create!(
      journal_id: @journal.id,
      issue_id:   @issue.id,
      project_id: @project.id,
      user_id:    User.current.id
    )
    log_history(:add)
  end

  def unpin(record)
    record.destroy
    log_history(:remove)
  end

  def log_history(action)
    journal = @issue.init_journal(User.current)
    journal.details << JournalDetail.new(
      property:  'important_note',
      prop_key:  @journal.id.to_s,
      old_value: (action == :remove ? @journal.id : nil),
      value:     (action == :add    ? @journal.id : nil)
    )
    unless @issue.save
      Rails.logger.warn(
        "redmine_pinned_issues: failed to journalize important_note " \
        "(issue ##{@issue.id}, journal ##{@journal.id}): " \
        "#{@issue.errors.full_messages.join(', ')}"
      )
      @issue.clear_journal
    end
  end
end