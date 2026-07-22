class ViewHooksV6 < Redmine::Hook::ViewListener
  def view_issues_context_menu_end(context)
    issues = context[:issues]
    return if issues.blank? || issues.size != 1

    # pin は一覧・詳細用。ガントチャート由来のメニューには出さない。
    back = context[:back].to_s
    return if back =~ %r{/issues/gantt\b} || back =~ %r{/gantt\b}

    issue = issues.first
    project = issue.project
    return unless project.module_enabled?(:pinned_issues_module) && User.current.allowed_to?(:pin_issues, project)

    if issue.pinned?
      link = link_to(l(:label_unpin_issue), '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue) })
      content_tag(:li, link)
    else
      content_tag(:li, class: 'folder') do
        link_to(l(:label_pin_issue), '#') +
        content_tag(:ul) do
            content_tag(:li, link_to(l(:label_pin_1_month),      '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '1_month') })) +
            content_tag(:li, link_to(l(:label_pin_1_week),       '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '1_week') })) +
            content_tag(:li, link_to(l(:label_pin_3_day),        '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '3_day') })) +
            content_tag(:li, link_to(l(:label_pin_1_day),        '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '1_day') })) +
            content_tag(:li, link_to(l(:label_pin_8_hour),       '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '8_hour') })) +
            content_tag(:li, link_to(l(:label_pin_4_hour),       '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '4_hour') })) +
            content_tag(:li, link_to(l(:label_pin_1_hour),       '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '1_hour') })) +
            content_tag(:li, link_to(l(:label_pin_30_min),       '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue, expires_in: '30_min') })) +
            content_tag(:li, link_to(l(:label_pin_no_expiration), '#', class: 'js-pin-toggle', data: { issue_url: pin_issue_path(issue) }))
          end
        end
    end
  end

  def view_layouts_base_body_bottom(context)
    html = ""
    controller = context[:controller]

    # pin が機能するのは issues 画面（一覧・詳細）のみ。
    # JSON埋め込みも JS/CSS ロードもこの画面に限定する。
    return '' unless controller.controller_name == 'issues'

    # issues画面（一覧・詳細共通）でピン留めデータをJSON埋め込み
    if controller.controller_name == 'issues'
      pinned_data = {}
      PinnedIssue.active.includes(:user).find_each do |pin|
        pinned_data[pin.issue_id] = {
          user: pin.user&.name || I18n.t('rake_pinned_issues.list_unknown_user'),
          expires_at: pin.expires_at&.iso8601
        }
      end

      labels = {
        pinned_by:     I18n.t(:label_pinned_by),
        remaining:     I18n.t(:label_pin_remaining),
        no_expiration: I18n.t(:label_pin_no_expiration),
        expired:       I18n.t(:label_pin_expired),
        day:           I18n.t(:label_pin_time_day),
        hour:          I18n.t(:label_pin_time_hour),
        min:           I18n.t(:label_pin_time_min)
      }

      data = { pins: pinned_data, labels: labels }

      if controller.action_name == 'show'
        issue = context[:issue] || controller.instance_variable_get(:@issue)
        data[:currentIssueId] = issue&.id
      end

      json_str = data.to_json.gsub('</', '<\/')
      html << content_tag(:script, json_str.html_safe, type: 'application/json', id: 'pinned-issues-data')
    end

    html << javascript_include_tag('pinned_issues.js', plugin: 'redmine_pinned_issues')
    html << stylesheet_link_tag('pinned_issues.css', plugin: 'redmine_pinned_issues')
    html.html_safe
  end

  def view_layouts_base_html_head(context)
    settings = Setting.plugin_redmine_pinned_issues || {}
    defaults = RedminePinnedIssues::DEFAULT_COLORS
    odd_color = settings['pinned_color_odd'].presence || defaults['pinned_color_odd']
    even_color = settings['pinned_color_even'].presence || defaults['pinned_color_even']
    icon_color = settings['pinned_icon_color'].presence || defaults['pinned_icon_color']

    css = <<~CSS
      :root {
        --pinned-bg-odd: #{odd_color};
        --pinned-bg-even: #{even_color};
        --pinned-icon-color: #{icon_color};
      }
    CSS

    if settings['enable_issue_colors'] == '1'
      css += <<~CSS

        /* Issue list colors (Farend_fancy compatible) */

        /* overdue */
        tr.odd.overdue  { background: #ffd8b2; }
        tr.even.overdue { background: #ffe5cc; }
        tr.odd.overdue td, tr.even.overdue td { border-color: #fcc; }

        /* priority-highest */
        tr.odd.priority-highest  { background: #ffc4c4; }
        tr.even.priority-highest { background: #ffd4d4; }
        tr.odd.priority-highest td, tr.even.priority-highest td { border-color: #ffb4b4; }
        tr.odd.priority-highest, tr.even.priority-highest,
        table.list tbody tr.odd.priority-highest:hover,
        table.list tbody tr.even.priority-highest:hover { color: #900; font-weight: bold; }
        tr.priority-highest a, tr.priority-highest:hover a { color: #900; }

        /* priority-high2 */
        tr.odd.priority-high2  { background: #ffc4c4; }
        tr.even.priority-high2 { background: #ffd4d4; }
        tr.odd.priority-high2 td, tr.even.priority-high2 td { border-color: #ffb4b4; }
        tr.odd.priority-high2, tr.even.priority-high2,
        table.list tbody tr.odd.priority-high2:hover,
        table.list tbody tr.even.priority-high2:hover { color: #900; }
        tr.priority-high2 a { color: #900; }

        /* priority-high3 */
        tr.odd.priority-high3  { background: #fee; }
        tr.even.priority-high3 { background: #fff2f2; }
        tr.odd.priority-high3 td, tr.even.priority-high3 td { border-color: #fcc; }
        tr.odd.priority-high3, tr.even.priority-high3,
        table.list tbody tr.odd.priority-high3:hover,
        table.list tbody tr.even.priority-high3:hover { color: #900; }
        tr.priority-high3 a { color: #900; }

        /* priority-lowest */
        tr.odd.priority-lowest  { background: #eaf7ff; }
        tr.even.priority-lowest { background: #f2faff; }
        tr.odd.priority-lowest td, tr.even.priority-lowest td { border-color: #add7f3; }
        tr.odd.priority-lowest, tr.even.priority-lowest,
        table.list tbody tr.odd.priority-lowest:hover,
        table.list tbody tr.even.priority-lowest:hover { color: #559; }
        tr.priority-lowest a { color: #559; }

        /* closed */
        table.list.issues tr.closed td { opacity: 0.7; }

        /* calendar overdue */
        table.cal div.overdue { background: #ffe5cc; }
      CSS
    end

    content_tag(:style) { css.html_safe }
  end
end