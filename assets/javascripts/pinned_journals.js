(function() {
  'use strict';

  // 「重要コメント」タブ：履歴タブの中身を important-note-row だけに絞り込む
  function showIssueHistoryImportant(tab, url) {
    var tab_content = $('#tab-content-history');
    if (!tab_content.length) { return false; }

    // まず Redmine 標準の notes 表示状態へリセットする。
    // properties タブは journal 内部の本文要素を hide するため（#33338）、
    // .journal を show するだけでは本文が戻らない。
    // 内部構造はバージョンで変わるのでコアの関数に委譲する。
    if (typeof showIssueHistory === 'function') {
      showIssueHistory('notes', null);
    } else {
      tab_content.parent().find('.tab-content').hide();
      tab_content.show();
    }

    // タブの選択状態を「重要コメント」へ付け替える
    tab_content.parent().find('div.tabs a').removeClass('selected');
    $('#tab-important').addClass('selected');
    if (window.replaceInHistory && url) { replaceInHistory(url); }

    // 重要登録されたコメントだけに絞る
    tab_content.find('.journal').hide();
    tab_content.find('.journal.important-note-row').show();
    return false;
  }

  // issue_history_tabs の onclick から呼ばれるため公開
  window.showIssueHistoryImportant = showIssueHistoryImportant;

  // ?tab=important でリロードされた場合の復元
  function restoreImportantTab() {
    if ($('#tab-important').hasClass('selected')) {
      showIssueHistoryImportant('important', null);
    }
  }

  document.addEventListener('turbo:load', restoreImportantTab);
  if (document.readyState !== 'loading') {
    restoreImportantTab();
  } else {
    document.addEventListener('DOMContentLoaded', restoreImportantTab);
  }
})();