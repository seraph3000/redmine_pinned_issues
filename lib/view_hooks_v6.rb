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

    odd_color = sanitize_color(settings['pinned_color_odd'], defaults['pinned_color_odd'])
    even_color = sanitize_color(settings['pinned_color_even'], defaults['pinned_color_even'])
    icon_color = sanitize_color(settings['pinned_icon_color'], defaults['pinned_icon_color'])

    css = <<~CSS
      :root {
        --pinned-bg-odd: #{odd_color};
        --pinned-bg-even: #{even_color};
        --pinned-icon-color: #{icon_color};
      }
    CSS
    content_tag(:style) { css.html_safe }
  end
end

private

# 16進カラーコードのみ許可。不正値はフォールバック
def sanitize_color(value, fallback)
  v = value.to_s.strip
  v =~ /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/ ? v : fallback
end