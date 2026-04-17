class PinnedIssuesController < ApplicationController
  before_action :find_issue
  before_action :authorize

  def toggle
    existing_pin = PinnedIssue.find_by(issue_id: @issue.id)

    # 期限切れレコードは削除して「存在しない」扱いに
    if existing_pin && existing_pin.expires_at.present? && existing_pin.expires_at <= Time.current
      existing_pin.destroy
      existing_pin = nil
    end

    if existing_pin
      existing_pin.destroy
      @message = l(:notice_issue_unpinned)
    else
      expires_at = calculate_expires_at(params[:expires_in])
      PinnedIssue.create!(
        issue: @issue,
        project: @project,
        user: User.current,
        expires_at: expires_at
      )
      @message = l(:notice_issue_pinned)
    end

    respond_to do |format|
      format.js { head :ok }
      format.any { head :ok }
    end
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def calculate_expires_at(expires_in)
    case expires_in
    when '30_min'  then 30.minutes.from_now
    when '1_hour'  then 1.hour.from_now
    when '4_hour'  then 4.hours.from_now
    when '8_hour'  then 8.hours.from_now
    when '1_day'   then 1.day.from_now
    when '3_day'   then 3.days.from_now
    when '1_week'  then 1.week.from_now
    when '1_month' then 1.month.from_now
    else nil
    end
  end
end