# plugins/redmine_pinned_issues/config/routes.rb

post '/issues/:issue_id/pin',       to: 'pinned_issues#toggle',   as: 'pin_issue'
post '/journals/:journal_id/pin',   to: 'pinned_journals#toggle', as: 'pin_journal'
