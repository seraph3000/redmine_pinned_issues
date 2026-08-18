class PinnedJournalsController < ApplicationController
  before_action :find_journal
  before_action :authorize_pin

  def toggle
    @issue.with_lock do
      existing = PinnedJournal.find_by(journal_id: @journal.id)
      if existing
        unpin(existing)
        @important = false
      elsif pin
        @important = true
      else
        @limit_reached = true
      end
    end

    respond_to do |format|
      format.js { render(@limit_reached ? :limit_reached : :toggle) }
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
    return render_403 unless @journal.visible?(User.current)
    return render_403 unless User.current.allowed_to?(:pin_journals, @project)
    return render_403 if @journal.notes.blank?
    true
  end

  # 上限に達している場合は false を返して登録しない。
  # 解除は上限に関わらず常に許可する。
  def pin
    limit = RedminePinnedIssues.important_note_limit
    if limit > 0 && PinnedJournal.where(issue_id: @issue.id).count >= limit
      @limit = limit
      return false
    end

    begin
      PinnedJournal.transaction(requires_new: true) do
        PinnedJournal.create!(
          journal_id: @journal.id,
          issue_id:   @issue.id,
          project_id: @project.id,
          user_id:    User.current.id
        )
      end
    rescue ActiveRecord::RecordNotUnique
      # ロックをすり抜けた二重送信。既に登録済みなので成功扱いにする。
      return true
    end

    log_history(:add)
    true
  end

  def unpin(record)
    record.destroy
    log_history(:remove)
  end

  # プロパティ更新履歴へ「重要 を登録/解除 (#note-N)」を記録する。
  # 必須カスタムフィールドが未入力の古いチケットでは save が通らないため、
  # 履歴記録の失敗は握りつぶす。重要登録/解除そのものは既に確定している。
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