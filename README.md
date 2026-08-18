# Redmine Pinned Issues Plugin

[日本語版はこちら / Japanese version](README_ja.md)

## Overview

This plugin adds a "pin" feature to Redmine's issue list, allowing specific issues to always appear at the top. Similar to Twitter's pinned tweets, it helps teams highlight important issues.

It also lets you mark individual comments as important, so the one note that actually matters on a long issue does not get buried under fifty others.

Supports expiration periods, role-based permissions, and per-project module activation for flexible operation.

## Screenshots

Pinned issues stay at the top of the list regardless of the sort order, with optional priority-based row coloring:

![Issue list with pinned issues](https://assets.st-note.com/img/1779545358-dWilhc2nvH56kMXyuPS01pA4.png)

Comments marked as important are highlighted, and a dedicated tab filters the history down to just those notes:

![Important notes tab](https://assets.st-note.com/img/1786521614-WRZOAa6McsqBpIdEPXo4Yy3G.png)

## Features

### Pinning issues

* **Pin/Unpin issues**: Pin specific issues to the top of the list or unpin them.
* **Priority display**: Pinned issues always appear at the top regardless of the sort order chosen by the user.
* **Expiration periods**: Set pin duration with 9 presets (30 minutes, 1/4/8 hours, 1/3 days, 1 week, 1 month, no expiration). Pins are automatically hidden once expired.
* **Smart sort order for pinned issues**: Among pinned issues, those with no expiration appear first, followed by those with longer remaining time.
* **Permission control**: Grant "Pin issues" permission to specific roles only.
* **Project module**: Enable or disable the pinning feature per project.
* **Visual indicators**:
  * Pinned issue rows are highlighted with a customizable background color (separate colors for odd/even rows).
  * A 📌 pin icon is displayed before the issue title on both the issue list and detail pages.
  * Hovering the icon shows who pinned the issue and how much time remains.
* **Context menu UI**: All operations are accessible via right-click context menu with a submenu for expiration selection. No page reloads or modal dialogs — everything happens inline via Ajax.

### Important notes

* **Mark comments as important**: A star button on each comment toggles its "important" state via Ajax.
* **Highlighted display**: Important comments get a colored underline on the header, a tinted background and a left accent border.
* **Dedicated tab**: An "Important notes" tab appears on the issue history and filters it down to the marked comments. The tab only shows up when at least one comment is marked.
* **Audit trail**: Marking and unmarking is recorded in the issue history with a link to the note.
* **Permission control**: Grant "Pin comments as important" permission to specific roles only. No separate project module is required — the permission belongs to the core issue tracking module.

### Issue list coloring (optional)

* Colorizes issue rows by priority level and overdue status, using the same palette as the Farend fancy theme.
* Works with the default theme — no additional theme installation required.
* Disabled by default; toggle it from the plugin settings page.

## Requirements

* Redmine 6.0, 6.1 or 7.0
* PostgreSQL 16 (other databases may work but are not officially tested)

Rails is whatever your Redmine version ships with (7.2 for Redmine 6.x, 8.0 for Redmine 7.0). No additional gems are required.

## Installation

1. Clone into Redmine's plugins directory

   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/seraph3000/redmine_pinned_issues.git
   ```
2. Navigate to your Redmine root directory and run the database migration:

   ```bash
   # Production
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```
3. Restart your Redmine web server:

   ```bash
   systemctl restart httpd
   ```

## Setup and Configuration

After installation, the following setup is required to use the feature.

### 1. Set permissions (Redmine administrator)

Configure which roles are allowed to pin issues and mark comments.

1. Go to **[Administration] > [Roles and permissions]**.
2. Click on the role you want to grant the permission to (e.g., Developer, Manager).
3. Under "Issue tracking", check the permissions you need:
   * **"Pin issues"** — pin and unpin issues.
   * **"Pin comments as important"** — mark and unmark comments.
4. Click [Save].

### 2. Enable the project module (Project administrator)

Each project administrator must enable the pinning feature for their project.

1. Navigate to the project where you want to enable the feature.
2. Open **[Settings] > [Modules]** tab.
3. Check **"Pin Issues"**.
4. Click [Save].

Important notes do not need this step. The permission lives under the core issue tracking module, so it is available in any project where issues exist.

### 3. Customize display colors (optional)

Adjust the highlight colors from the plugin settings page.

1. Go to **[Administration] > [Plugins]**.
2. Click "Configure" next to the Redmine Pinned Issues plugin.
3. Adjust the following using the color picker or hex code input:
   * Pinned row background color (odd)
   * Pinned row background color (even)
   * Important note header underline color
   * Important note background color
   * Important note left border color
4. Optionally enable **"Enable issue list coloring"** to colorize rows by priority and overdue status.
5. Click [Save]. Use "Reset to default" next to any color to restore its default value.

Colors must be given as hex values (`#RGB` or `#RRGGBB`). Anything else falls back to the default.

## Usage

### Pinning an issue

1. On the issue list page, right-click on the issue you want to pin.
2. Select **"Pin this issue"** from the context menu, then choose a duration from the submenu:
   * No expiration
   * 1 month / 1 week / 3 days / 1 day
   * 8 hours / 4 hours / 1 hour / 30 minutes
3. The issue is pinned immediately without a page reload.
4. To unpin, right-click again and select **"Unpin issue"**.

Pinned issues are displayed with a 📌 icon before the title and a highlighted background. The detail page also shows the pin icon next to the issue title. Hovering the icon reveals who pinned it and the remaining time.

### Marking a comment as important

1. Open an issue and find the comment you want to highlight.
2. Click the star button in the comment's action bar.
3. The comment is highlighted immediately without a page reload, and an "Important notes" tab appears above the history.
4. Click the star again to unmark it.

Only comments with a note body can be marked. Property-change-only entries do not get the button.

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

v0.4.2 (2026-08-18)

* Added a per-issue limit for important notes, configurable from the plugin
  settings page. Defaults to 0 (unlimited).
* The star button is now disabled for a few seconds after each click,
  preventing accidental repeated toggles.
* Toggle requests on the same issue are now serialized, so simultaneous
  operations from multiple tabs no longer bypass the limit or create
  duplicate records.
* Fixed a duplicate submission causing an error under PostgreSQL.
* Replaced the star icon (fav) with a custom exclamation mark SVG sprite for the important toggle button.

v0.4.1 (2026-08-18)

* Removed duplicate definitions of showIssueHistoryImportant.

v0.4.0 (2026-08-12)

* Added the important notes feature.
  Comments can be marked as important with a star button, are highlighted in the
  history, and can be filtered through a dedicated "Important notes" tab.
  Marking and unmarking is recorded in the issue history.
  Controlled by the new "Pin comments as important" permission.
* Added three color settings for important notes (header underline, background, left border).

v0.3.0 (2026-07-22)

* Added optional issue list coloring (Farend fancy theme compatible).
  Colorizes issue rows by priority level and overdue status using the same colors as the Farend fancy theme.
  Works with the default theme — no additional theme installation required.
  Can be toggled on/off from the plugin settings page (disabled by default).
* Added Redmine 7.0 support.

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
