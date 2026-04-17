class ViewHooksV6 < Redmine::Hook::ViewListener
  def view_issues_context_menu_end(context)
    issues = context[:issues]
    return if issues.blank? || issues.size != 1

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
    if context[:controller].controller_name == 'issues' && context[:controller].action_name == 'show'
      issue = context[:issue]
      if issue&.pinned?
        html << "<div id='pinned-icon-show-template' style='display:none;'><span class='pinned-icon-wrapper-show'>📍</span></div>"
      end
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

    # 詳細画面でピン留めチケット表示中の場合、h2の前に📍を追加
    controller = context[:controller]
    if controller && controller.controller_name == 'issues' && controller.action_name == 'show'
      issue = controller.instance_variable_get(:@issue)
      if issue.respond_to?(:pinned?) && issue.pinned?
        css += <<~CSS
          body.controller-issues.action-show h2::before {
            content: "📍";
            margin-right: 10px;
            font-family: "Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji", sans-serif;
          }
        CSS
      end
    end
    content_tag(:style) { css.html_safe }
  end
end