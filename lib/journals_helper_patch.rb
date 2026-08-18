module JournalsHelperPatch
  def render_journal_actions(issue, journal, options = {})
    html = super
    # notesありコメントだけ対象。プロパティ変更履歴には出さない
    return html unless journal.notes.present?
    return html unless User.current.allowed_to?(:pin_journals, issue.project)

    on    = journal.respond_to?(:important?) && journal.important?
    label = on ? l(:label_important_unpin) : l(:label_important_pin)

    css = ['icon-only', 'important-toggle']
    css << 'is-on' if on

    # sprite_icon にラベルを渡さない（SVGのみ）。
    # 文言は title 属性で持たせ、トグル時のDOM操作を is-on と title に限定する。
    fav_link = link_to(
      sprite_icon('pinned-important', plugin: 'redmine_pinned_issues'),
      pin_journal_path(journal_id: journal.id),
      remote: true, method: 'post',
      title: label,
      class: css.join(' ')
    )
    # 本体のlinks列の先頭に差す
    (fav_link + html).html_safe
  end
end