(function() {
  'use strict';

  function initPinnedIssues() {
    // 1. 詳細画面タイトルへのアイコン挿入（遷移のたびに実行が必要）
    var template = document.getElementById('pinned-icon-show-template');
    var header = document.querySelector('.controller-issues.action-show h2');
    
    if (template && header && !header.querySelector('.pinned-icon-wrapper-show')) {
      header.insertAdjacentHTML('afterbegin', template.innerHTML);
    }

    // 2. イベントリスナーの設定（一度だけ設定）
    if (window.pinnedIssuesBound) return;
    
    document.addEventListener('click', function(e) {
      var trigger = e.target.closest('.js-pin-toggle');
      if (trigger) {
        e.preventDefault();
        e.stopPropagation();

        var issueUrl = trigger.dataset.issueUrl;
        var csrfToken = document.querySelector('meta[name="csrf-token"]');
        
        var url = issueUrl;
        var params = new URLSearchParams();
      
        if (issueUrl.indexOf('?') !== -1) {
          var parts = issueUrl.split('?');
          url = parts[0];
          params = new URLSearchParams(parts[1]);
        }
        
        var headers = { 'X-Requested-With': 'XMLHttpRequest' };
        if (csrfToken) { headers['X-CSRF-Token'] = csrfToken.getAttribute('content'); }

        fetch(url, { method: 'POST', body: params, headers: headers })
        .then(function(response) {
          if (response.ok) {
            var contextMenu = document.getElementById('context-menu');
            if (contextMenu) { contextMenu.style.display = 'none'; }
            window.location.reload();
          } else {
            alert('Error: ' + response.status);
          }
        })
        .catch(function(err) { alert('Error: ' + err.message); });
      }
    });
    window.pinnedIssuesBound = true;
  }

  document.addEventListener('turbo:load', initPinnedIssues);
  if (document.readyState !== 'loading') {
    initPinnedIssues();
  } else {
    document.addEventListener('DOMContentLoaded', initPinnedIssues);
  }
})();