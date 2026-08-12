if Gem::Version.new(Redmine::VERSION) < Gem::Version.new('6.0.0')
  raise "redmine_pinned_issues requires Redmine 6.0 or later. Current version: #{Redmine::VERSION}"
end

module RedminePinnedIssues
  # デフォルトカラーを一箇所で管理
  DEFAULT_COLORS = {
    'pinned_color_odd'  => '#f5fd81',
    'pinned_color_even' => '#fffadb',
    'important_header_color' => '#f55d2f',
    'important_border_color' => '#f04a89',
    'important_bg_color'     => '#fff6f2',
  }.freeze
  DEFAULT_SETTINGS = DEFAULT_COLORS.merge({
    'enable_issue_colors' => '0',
  }).freeze
end

Redmine::Plugin.register :redmine_pinned_issues do
  name 'Redmine Pinned Issues plugin'
  author 'seraph3000'
  description 'A plugin to pin issues to the top of the list with an expiration date.'
  version '0.4.0'
  url 'https://github.com/seraph3000/redmine_pinned_issues'
  author_url 'https://github.com/seraph3000'

  settings default: RedminePinnedIssues::DEFAULT_SETTINGS, partial: 'settings/pinned_issues_settings'

  project_module :pinned_issues_module do
    permission :pin_issues, { pinned_issues: [:toggle] }, require: :member
  end
  # コメントの重要化は専用モジュールを持たず、コアの issue_tracking に属させる。
  # チケット管理が無効なプロジェクトにはコメント自体が存在しないため、
  # 実質的に「モジュール選択不要で常時有効」となる。
  project_module :issue_tracking do
    permission :pin_journals, { pinned_journals: [:toggle] }, require: :member
  end
end

# パッチの読み込み
require File.dirname(__FILE__) + '/lib/issue_patch'
require File.dirname(__FILE__) + '/lib/issue_query_patch'
require File.dirname(__FILE__) + '/lib/journal_patch'
require File.dirname(__FILE__) + '/lib/issues_helper_patch'
require File.dirname(__FILE__) + '/lib/journals_helper_patch'

# 直接パッチを適用（二重適用防止つき）
Issue.prepend(IssuePatch) unless Issue.ancestors.include?(IssuePatch)
IssueQuery.prepend(IssueQueryPatch) unless IssueQuery.ancestors.include?(IssueQueryPatch)
Journal.prepend(JournalPatch) unless Journal.ancestors.include?(JournalPatch)

# ビューフック読み込み（Redmine 6以降専用）
require File.dirname(__FILE__) + '/lib/view_hooks_v6'

Rails.application.config.after_initialize do
  IssuesHelper.prepend(IssuesHelperPatch) unless IssuesHelper.ancestors.include?(IssuesHelperPatch)
  JournalsHelper.prepend(JournalsHelperPatch) unless JournalsHelper.ancestors.include?(JournalsHelperPatch)
end