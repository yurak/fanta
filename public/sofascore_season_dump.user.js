// ==UserScript==
// @name         MantraFootball — SofaScore season id dumper (one-off)
// @namespace    mantrafootball
// @version      1.0.0
// @description  Walks every round of a SofaScore season and copies [{round, sofaId, home, away}] to the clipboard. One-off helper to map source_match_id in bulk.
// @match        https://www.sofascore.com/*
// @connect      api.sofascore.com
// @grant        GM_xmlhttpRequest
// @grant        GM_setClipboard
// ==/UserScript==

/*
 * Use:
 *   Open any sofascore.com page, click "🗓️ Dump season → clipboard",
 *   confirm the "uniqueTournament-season" pair (UPL 2026/27 = 218-97214).
 *   It fetches every round, copies a JSON array to your clipboard, then
 *   paste it back to the admin who turns it into a console update command.
 */

const SOFA_ROUND = "https://api.sofascore.com/api/v1/unique-tournament";
const MAX_ROUNDS = 45;

function gmRequest(opts) {
  return new Promise((resolve, reject) => {
    GM_xmlhttpRequest({
      ...opts,
      onload: (res) => resolve(res),
      onerror: (err) => reject(err),
      ontimeout: () => reject(new Error("timeout")),
    });
  });
}

async function fetchRound(ut, season, round) {
  const res = await gmRequest({
    method: "GET",
    url: `${SOFA_ROUND}/${ut}/season/${season}/events/round/${round}`,
    headers: { Accept: "application/json" },
  });
  if (res.status === 404) return [];
  if (res.status !== 200) throw new Error(`round ${round} → HTTP ${res.status}`);
  return JSON.parse(res.responseText).events || [];
}

async function dumpSeason() {
  const pair = prompt('SofaScore "uniqueTournament-season" pair:', "218-97214");
  if (!pair) return;
  const [ut, season] = pair.trim().split("-");

  const out = [];
  let emptyStreak = 0;
  for (let round = 1; round <= MAX_ROUNDS; round++) {
    let events;
    try {
      events = await fetchRound(ut, season, round);
    } catch (e) {
      alert(`Stopped at round ${round}: ${e.message}`);
      break;
    }
    if (!events.length) {
      if (++emptyStreak >= 2) break; // two empty rounds in a row → season is over
      continue;
    }
    emptyStreak = 0;
    for (const ev of events) {
      out.push({
        round: ev.roundInfo && ev.roundInfo.round,
        sofaId: String(ev.id),
        home: ev.homeTeam && ev.homeTeam.name,
        away: ev.awayTeam && ev.awayTeam.name,
      });
    }
  }

  const json = JSON.stringify(out, null, 2);
  GM_setClipboard(json);
  console.log(json);
  alert(`Copied ${out.length} events to clipboard. Paste them to the admin.`);
}

function addButton() {
  if (document.getElementById("mantra-dump-btn")) return;

  const btn = document.createElement("button");
  btn.id = "mantra-dump-btn";
  btn.textContent = "🗓️ Dump season → clipboard";
  Object.assign(btn.style, {
    position: "fixed", bottom: "60px", right: "16px", zIndex: 99999,
    padding: "10px 14px", background: "#0a7", color: "#fff",
    border: "none", borderRadius: "8px", fontSize: "14px", cursor: "pointer",
    boxShadow: "0 2px 8px rgba(0,0,0,0.3)",
  });
  btn.addEventListener("click", () => {
    btn.disabled = true;
    btn.textContent = "Dumping…";
    dumpSeason().finally(() => {
      btn.disabled = false;
      btn.textContent = "🗓️ Dump season → clipboard";
    });
  });
  document.body.appendChild(btn);
}

addButton();
