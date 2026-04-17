# plugins/redmine_pinned_issues/lib/tasks/pinned_issues.rake

namespace :redmine do
  namespace :pinned_issues do
    desc I18n.t(:rake_desc_cleanup, default: 'Delete expired pinned issue records from DB')
    task cleanup: :environment do
      expired = PinnedIssue.expired
      count = expired.count
      if count.zero?
        puts I18n.t('rake_pinned_issues.no_expired')
      else
        puts I18n.t('rake_pinned_issues.cleanup_count', count: count)
        expired.destroy_all
        puts I18n.t('rake_pinned_issues.cleanup_done')
      end
    end

    desc I18n.t(:rake_desc_status, default: 'Show current pinned issues status')
    task status: :environment do
      total   = PinnedIssue.count
      active  = PinnedIssue.active.count
      expired = PinnedIssue.expired.count

      puts I18n.t('rake_pinned_issues.status_header')
      puts I18n.t('rake_pinned_issues.status_total', count: total)
      puts I18n.t('rake_pinned_issues.status_active', count: active)
      puts I18n.t('rake_pinned_issues.status_expired', count: expired)
    end

    desc I18n.t(:rake_desc_list, default: 'List active pinned issues')
    task list: :environment do
      pins = PinnedIssue.active.includes(:issue, :project, :user).order(:created_at)
      if pins.empty?
        puts I18n.t('rake_pinned_issues.no_active')
      else
        puts I18n.t('rake_pinned_issues.list_header')
        pins.each do |pin|
          expires = pin.expires_at ? pin.expires_at.strftime('%Y-%m-%d %H:%M') : I18n.t('rake_pinned_issues.list_no_expiration')
          project = pin.project&.name || I18n.t('rake_pinned_issues.list_unknown_project')
          issue_str = pin.issue ? "##{pin.issue.id} #{pin.issue.subject}" : I18n.t('rake_pinned_issues.list_unknown_issue')
          user    = pin.user&.name || I18n.t('rake_pinned_issues.list_unknown_user')
          puts "[#{project}] #{issue_str}"
          puts I18n.t('rake_pinned_issues.list_entry', expires: expires, user: user)
        end
      end
    end

    desc I18n.t(:rake_desc_help, default: 'Show available tasks for this plugin')
    task help: :environment do
      puts <<~HELP
        #{I18n.t('rake_pinned_issues.help_header')}

          redmine:pinned_issues:cleanup
              #{I18n.t('rake_pinned_issues.help_desc_cleanup')}

          redmine:pinned_issues:status
              #{I18n.t('rake_pinned_issues.help_desc_status')}

          redmine:pinned_issues:list
              #{I18n.t('rake_pinned_issues.help_desc_list')}

          redmine:pinned_issues:help
              #{I18n.t('rake_pinned_issues.help_desc_help')}

          #{I18n.t('rake_pinned_issues.help_usage_label')}
          bundle exec rake redmine:pinned_issues:cleanup RAILS_ENV=production

          #{I18n.t('rake_pinned_issues.help_cron_label')}
          0 3 * * * cd /path/to/redmine && bundle exec rake redmine:pinned_issues:cleanup RAILS_ENV=production

      HELP
    end
  end
end
