# Redmine Pinned Issues Plugin

[日本語版はこちら / Japanese version](README_ja.md)

## Overview

This plugin adds a "pin" feature to Redmine's issue list, allowing specific issues to always appear at the top. Similar to Twitter's pinned tweets, it helps teams highlight important issues.

Supports expiration periods, role-based permissions, and per-project module activation for flexible operation.

## Features

* **Pin/Unpin issues**: Pin specific issues to the top of the list or unpin them.
* **Priority display**: Pinned issues always appear at the top regardless of the sort order chosen by the user.
* **Expiration periods**: Set pin duration with 9 presets (30 minutes, 1/4/8 hours, 1/3 days, 1 week, 1 month, no expiration). Pins are automatically hidden once expired.
* **Permission control**: Grant "Pin issues" permission to specific roles only.
* **Project module**: Enable or disable the pinning feature per project.
* **Visual indicators**:
  * Pinned issue rows are highlighted with a customizable background color (separate colors for odd/even rows).
  * A 📌 pin icon is displayed before the issue title on both the issue list and detail pages.
  * Hovering over the 📌 icon shows a tooltip with who pinned the issue and the remaining time.
* **Customizable colors**: Background colors and icon color can be configured from the plugin settings page.
* **Context menu UI**: All operations are accessible via right-click context menu with a submenu for expiration selection. No page reloads or modal dialogs — everything happens inline via Ajax.
* **Smart sort order for pinned issues**: Among pinned issues, those with no expiration appear first, followed by those with longer remaining time.
> **Note (how expiration is calculated):**
> Durations such as "1 week" and "1 month" are calculated on a calendar basis (Ruby on Rails).
> In particular, "1 month" is **not** a fixed 30 days but the same day of the next month, so the remaining time varies between 28–31 days depending on when the issue was pinned (e.g., ~31 days if pinned in May, ~28 days in February).
> The tooltip displays this actual remaining time as-is.

## Requirements

* Redmine 6.0+ (also supports 6.1)
* Ruby 3.2+
* Ruby on Rails 7.2
* PostgreSQL 16 (other databases may work but are not officially tested)

## Installation

1. Clone into Redmine's plugins directory and run the migration:

```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/seraph3000/redmine_pinned_issues.git
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```
2. Depending on your environment, you may need to recompile assets:

```bash
   RAILS_ENV=production bundle exec rake assets:clobber
   RAILS_ENV=production bundle exec rake assets:precompile
```

   For subdirectory deployments (e.g. `/redmine`), prefix the commands with `RAILS_RELATIVE_URL_ROOT=/redmine`.
   Then restart your web server (e.g. `systemctl restart httpd`).

## Uninstall

1. Revert the plugin's migrations (this drops the `pinned_issues` table and deletes all pin data):

```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate NAME=redmine_pinned_issues VERSION=0 RAILS_ENV=production
```
2. Remove the plugin directory:

```bash
   rm -rf /path/to/redmine/plugins/redmine_pinned_issues
```
3. Recompile assets if needed for your environment:

```bash
   RAILS_ENV=production bundle exec rake assets:clobber
   RAILS_ENV=production bundle exec rake assets:precompile
```
4. Restart your web server (e.g. `systemctl restart httpd`).

## Setup and Configuration

After installation, the following setup is required to use the feature.

### 1. Set permissions (Redmine administrator)

Configure which roles are allowed to pin issues.

1. Go to **[Administration] > [Roles and permissions]**.
2. Click on the role you want to grant the permission to (e.g., Developer, Manager).
3. Under "Issue tracking", check **"Pin issues"**.
4. Click [Save].

### 2. Enable the project module (Project administrator)

Each project administrator must enable the feature for their project.

1. Navigate to the project where you want to enable the feature.
2. Open **[Settings] > [Modules]** tab.
3. Check **"Pin Issues"**.
4. Click [Save].

### 3. Customize display colors (optional)

Adjust the background colors of pinned rows and the icon color from the plugin settings page.

1. Go to **[Administration] > [Plugins]**.
2. Click "Configure" next to the Redmine Pinned Issues plugin.
3. Adjust the following colors using the color picker or hex code input:
   * Pinned row background color (odd)
   * Pinned row background color (even)
4. Click [Save]. Use "Reset to default" to restore default colors.

## Usage

1. On the issue list page, right-click on the issue you want to pin.
2. Select **"Pin this issue"** from the context menu, then choose a duration from the submenu:
   * No expiration
   * 1 month / 1 week / 3 days / 1 day
   * 8 hours / 4 hours / 1 hour / 30 minutes
3. The issue is pinned immediately without a page reload.
4. To unpin, right-click again and select **"Unpin issue"**.

Pinned issues are displayed with a 📌 icon before the title and a highlighted background. The detail page also shows the pin icon next to the issue title.

## Rake Tasks

This plugin provides several Rake tasks for maintenance and inspection.

```bash
# Display available tasks
bundle exec rake redmine:pinned_issues:help RAILS_ENV=production

# Show current status (total/active/expired counts)
bundle exec rake redmine:pinned_issues:status RAILS_ENV=production

# List all active pinned issues
bundle exec rake redmine:pinned_issues:list RAILS_ENV=production

# Delete expired pin records from the database
bundle exec rake redmine:pinned_issues:cleanup RAILS_ENV=production
```

### Automatic cleanup (recommended)

Expired pins are automatically removed and the issue returns to its normal position in the sort order, but the records remain in the database.

```cron
# Delete expired pins at 3:00 AM every day
0 3 * * * cd /path/to/redmine && /usr/bin/flock -xn /tmp/redmine_pinned_issues_cleanup.lock -c 'RAILS_ENV=production bundle exec rake redmine:pinned_issues:cleanup'
```

## Changelog

v0.2.2 (2026-05-23)

* Added a tooltip on the 📌 icon showing who pinned the issue and the remaining time on hover.
* Documented that expiration periods are calendar-based ("1 month" is not a fixed 30 days).

v0.2.1 (2026-05-20)

* Removed leftover debug CSS class (patch-alive-test) from issue row output.

v0.2.0 (2026-04-18)

* Initial public release.
* Pin/Unpin issues via right-click context menu.
* 9 expiration presets (30 min to no expiration).
* Role-based permission control and per-project module activation.
* Customizable background colors for pinned rows (odd/even).
* 📌 icon display on issue list and detail pages.
* Smart sort order: no-expiration first, then by remaining time descending.
* Rake tasks for status, list, cleanup, and help.
* Automatic expired-pin filtering via scoped associations.

## Author

seraph3000 ([GitHub](https://github.com/seraph3000))

## License

MIT License
