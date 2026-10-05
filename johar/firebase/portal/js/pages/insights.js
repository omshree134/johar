// Training insights: where workers struggle, per module and per question.
import { store, passMark } from '../store.js';
import { t } from '../i18n.js';
import { esc, pct, fmtNum, barRows, columns, colorFor } from '../ui.js';
import { MODULES } from '../config.js';
import { pageHead, moduleBadge, moduleTitle, qText, loading, periodLabel } from './common.js';

let current = MODULES[0].id;

export function render(el) {
  if (loading(el)) return;
  const stats = store.moduleStats();
  const s = stats.find((x) => x.m.id === current);
  const hist = store.scoreHistogram(current);
  const missed = store.missedQuestions(current);
  const allQs = Object.entries(store.questions[current] ?? {});
  const neverMissed = allQs.filter(([qid]) => !missed.some((m) => m.qid === qid));

  el.innerHTML = `
    ${pageHead(t('insightsTitle'), `${t('insightsSub')} · ${periodLabel()}`)}
    <div class="chips" style="margin-bottom:16px">${MODULES.map((m) => `<button class="chip ${m.id === current ? 'on' : ''}" data-m="${m.id}" type="button">
      <span class="module-cell">${moduleBadge(m.id, 18)}${esc(moduleTitle(m.id))}</span></button>`).join('')}</div>

    <section class="grid kpis">
      ${[
        [t('kPass'), pct(s.passRate), `${fmtNum(s.attempts)} ${t('attempts')}`],
        [t('firstTime'), pct(s.firstTimePass), t('firstTimeHint')],
        [t('test'), pct(s.avgQuiz), t('avgScore')],
        [t('arPractice'), pct(s.avgAr), t('avgScore')],
        [t('lifeSafetyFails'), fmtNum(s.criticalFails), t('lifeSafetyHint')],
        [t('after7'), pct(s.retention), s.retentionN ? `${s.retentionN} ${t('checks')}` : t('noData')],
      ].map(([l, val, n]) => `<div class="card kpi"><span class="label">${esc(l)}</span><span class="value num">${esc(val)}</span><span class="note">${esc(n)}</span></div>`).join('')}
    </section>

    <section class="grid cols-2 mt">
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('distTitle'))}</h2><p>${esc(t('distHint', { mark: passMark }))}</p></div></div>
        ${columns({ labels: hist.map((_, i) => `${i * 10}`), values: hist, colors: hist.map((_, i) => (i * 10 >= passMark ? 'var(--green)' : i * 10 >= passMark - 20 ? 'var(--yellow)' : 'var(--red)')) })}
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('compareTitle'))}</h2><p>${esc(t('compareHint'))}</p></div></div>
        ${barRows(stats.map((x) => ({ label: `<span class="module-cell">${moduleBadge(x.m.id, 20)}${esc(moduleTitle(x.m.id).split(' ')[0])} · ${esc(t('test'))}</span>`, value: x.avgQuiz, color: 'var(--manganese)' }))
          .concat(stats.map((x) => ({ label: `<span class="module-cell">${moduleBadge(x.m.id, 20)}${esc(moduleTitle(x.m.id).split(' ')[0])} · AR</span>`, value: x.avgAr, color: 'var(--ochre)' }))), { mark: passMark })}
      </div>
    </section>

    <section class="card mt">
      <div class="card-head"><div class="grow"><h2>${esc(t('questionsTitle'))}</h2><p>${esc(t('questionsHint'))}</p></div></div>
      ${missed.length || allQs.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('question'))}</th><th class="right">${esc(t('timesMissed'))}</th><th style="min-width:220px">${esc(t('missRate'))}</th></tr></thead><tbody>
        ${missed.map((q) => `<tr><td>${q.critical ? `<span class="pill failed" style="margin-bottom:4px">${esc(t('critical'))}</span><br>` : ''}<b>${esc(qText(q.prompt) || q.qid)}</b>
          ${q.explanation ? `<div class="muted small">${esc(qText(q.explanation))}</div>` : ''}</td>
          <td class="right num">${q.n}</td><td>${barRows([{ label: '', value: q.rate, color: colorFor(100 - q.rate, passMark) }])}</td></tr>`).join('')}
        ${neverMissed.map(([qid, q]) => `<tr><td>${q.critical ? `<span class="pill failed" style="margin-bottom:4px">${esc(t('critical'))}</span><br>` : ''}${esc(qText(q.prompt) || qid)}</td>
          <td class="right num">0</td><td>${barRows([{ label: '', value: 0, color: 'var(--green)' }])}</td></tr>`).join('')}
      </tbody></table></div>
      <p class="small muted" style="margin:10px 0 0">${esc(t('missRateNote'))}</p>` : `<p class="muted">${esc(t('noData'))}</p>`}
    </section>`;

  el.querySelectorAll('[data-m]').forEach((b) => b.addEventListener('click', () => { current = b.dataset.m; render(el); }));
}
