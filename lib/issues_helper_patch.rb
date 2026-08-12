module IssuesHelperPatch
  def show_detail(detail, no_html = false, options = {})
    return super unless detail.property == 'important_note'

    journal_id = detail.prop_key.to_i
    journal = Journal.find_by(id: journal_id)

    label  = l(:field_important_note)
    action = detail.value.present? ? l(:text_important_added) : l(:text_important_unpinned)

    if journal && journal.journalized.is_a?(Issue)
      issue   = journal.journalized
      indexed = issue.visible_journals_with_index.find { |j| j.id == journal_id }
      indice  = indexed ? indexed.indice : nil
    end

    if no_html
      # テキスト版：番号だけ
      target = indice ? "#note-#{indice}" : "##{journal_id}"
      l(:text_important_note_detail, label: label, action: action, target: target)
    else
      if indice
        link = link_to("#note-#{indice}", issue_path(issue, anchor: "note-#{indice}"))
      else
        link = "##{journal_id}"
      end
      raw_text = l(:text_important_note_detail, label: label, action: action, target: '%TARGET%')
      html = ERB::Util.html_escape(raw_text).gsub('%TARGET%', link.to_s)
      content_tag('strong', html.html_safe)
    end
  end

  def issue_history_tabs
    tabs = super
    if @journals.present? &&
      PinnedJournal.where(journal_id: @journals.map(&:id)).exists?
      tabs << {
        name: 'important',
        label: :label_important_notes_tab,
        onclick: 'showIssueHistoryImportant("important", this.href)'
      }
    end
    tabs
  end
end
