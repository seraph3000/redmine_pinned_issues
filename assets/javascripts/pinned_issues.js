(function() {
  'use strict';

  function getPinnedData() {
    var el = document.getElementById('pinned-issues-data');
    if (!el) return null;
    try { return JSON.parse(el.textContent); } catch(e) { return null; }
  }

  function formatRemaining(expiresAt, labels) {
    if (!expiresAt) return labels.no_expiration;

    var diff = new Date(expiresAt) - new Date();
    if (diff <= 0) return labels.expired;

    var totalMin = Math.floor(diff / 60000);
    var days  = Math.floor(totalMin / 1440);
    var hours = Math.floor((totalMin % 1440) / 60);
    var mins  = totalMin % 60;

    var parts = [];
    if (days  > 0) parts.push(days + labels.day);
    if (hours > 0) parts.push(hours + labels.hour);
    if (mins  > 0 || parts.length === 0) parts.push(mins + labels.min);

    return labels.remaining + ' ' + parts.join(' ');
  }

  function buildTooltip(pinInfo, labels) {
    return labels.pinned_by + ': ' + pinInfo.user + '\n' + formatRemaining(pinInfo.expires_at, labels);
  }

  function initPinnedIssues() {
    var data = getPinnedData();

    // 1. 一覧画面：ピン留め行にツールチップ付きアイコン挿入
    var pinnedRows = document.querySelectorAll('tr.issue.pinned');
    for (var i = 0; i < pinnedRows.length; i++) {
      var tr = pinnedRows[i];
      var subjectTd = tr.querySelector('td.subject');
      if (!subjectTd || subjectTd.querySelector('.pinned-icon-wrapper')) continue;

      var match = tr.id && tr.id.match(/^issue-(\d+)$/);
      if (!match) continue;

      var issueId = parseInt(match[1], 10);
      var span = document.createElement('span');
      span.className = 'pinned-icon-wrapper';
      span.textContent = '\uD83D\uDCCC';

      if (data && data.pins && data.pins[issueId]) {
        span.title = buildTooltip(data.pins[issueId], data.labels);
      }

      subjectTd.insertBefore(span, subjectTd.firstChild);
    }

    // 2. 詳細画面：h2にツールチップ付きアイコン挿入
    var header = document.querySelector('.controller-issues.action-show h2');
    if (header && !header.querySelector('.pinned-icon-wrapper-show') && data && data.currentIssueId) {
      var pinInfo = data.pins && data.pins[data.currentIssueId];
      if (pinInfo) {
        var showSpan = document.createElement('span');
        showSpan.className = 'pinned-icon-wrapper-show';
        showSpan.textContent = '\uD83D\uDCCC';
        showSpan.title = buildTooltip(pinInfo, data.labels);
        header.insertBefore(showSpan, header.firstChild);
      }
    }

    // 3. イベントリスナー（一度だけ）
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