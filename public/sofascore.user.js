// ==UserScript==
// @name         MantraFootball — SofaScore round importer
// @namespace    mantrafootball
// @version      1.0.0
// @description  Fetches SofaScore event + lineups JSON from the browser and sends a whole round to MantraFootball (bypasses the server-side block).
// @match        https://www.sofascore.com/*
// @connect      api.sofascore.com
// @connect      mantrafootball.org
// @connect      staging.mantrafootball.org
// @grant        GM_xmlhttpRequest
// ==/UserScript==

/*
 * Setup (once):
 *   1. Install Tampermonkey (or Violentmonkey) and add this script.
 *   2. Fill in MANTRA_BASE and INGEST_TOKEN below (token = the server's
 *      SOFASCORE_INGEST_TOKEN env value; ask the admin).
 *   3. In Mantra, set each UPL match's `source_match_id` to its SofaScore event id.
 *
 * Use (per round):
 *   Open any sofascore.com page, click the "⚽ Import round → Mantra" button,
 *   enter the Mantra tournament_round id. The script asks Mantra which SofaScore
 *   event ids belong to that round, fetches each event + lineups from your
 *   browser, posts them back, and Mantra injects the scores automatically.
 */

const MANTRA_BASE = "https://mantrafootball.org";
const INGEST_TOKEN = "PASTE_SOFASCORE_INGEST_TOKEN_HERE";

const SOFA_API = "https://api.sofascore.com/api/v1/event";

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

async function fetchText(url) {
  // Same-site fetch from a sofascore.com page — the browser is not blocked.
  const res = await fetch(url, { credentials: "include" });
  if (!res.ok) throw new Error(`SofaScore ${res.status} for ${url}`);
  return res.text();
}

async function roundSofaIds(roundId) {
  const res = await gmRequest({
    method: "GET",
    url: `${MANTRA_BASE}/api/sofascore/matches?tournament_round_id=${encodeURIComponent(roundId)}`,
    headers: { "X-Ingest-Token": INGEST_TOKEN },
  });
  if (res.status !== 200) throw new Error(`Mantra list ${res.status}: ${res.responseText}`);
  return JSON.parse(res.responseText).data;
}

async function importMatch(sofaId) {
  const baseData = await fetchText(`${SOFA_API}/${sofaId}`);
  const lineupsData = await fetchText(`${SOFA_API}/${sofaId}/lineups`);

  const res = await gmRequest({
    method: "POST",
    url: `${MANTRA_BASE}/api/sofascore/matches`,
    headers: { "X-Ingest-Token": INGEST_TOKEN, "Content-Type": "application/json" },
    data: JSON.stringify({ sofascore_id: sofaId, base_data: baseData, lineups_data: lineupsData }),
  });
  return { sofaId, status: res.status, body: res.responseText };
}

async function importRound() {
  const roundId = prompt("Mantra tournament_round id for this UPL round:");
  if (!roundId) return;

  let sofaIds;
  try {
    sofaIds = await roundSofaIds(roundId.trim());
  } catch (e) {
    alert(`Could not read round from Mantra:\n${e.message}`);
    return;
  }
  if (!sofaIds.length) {
    alert("No matches with a source_match_id in that round.");
    return;
  }

  const results = [];
  for (const sofaId of sofaIds) {
    try {
      results.push(await importMatch(sofaId));
    } catch (e) {
      results.push({ sofaId, status: "error", body: e.message });
    }
  }

  const ok = results.filter((r) => r.status === 200).length;
  const lines = results.map((r) => `${r.sofaId}: ${r.status}`).join("\n");
  alert(`Imported ${ok}/${results.length} matches.\n\n${lines}`);
}

function addButton() {
  if (document.getElementById("mantra-import-btn")) return;

  const btn = document.createElement("button");
  btn.id = "mantra-import-btn";
  btn.textContent = "⚽ Import round → Mantra";
  Object.assign(btn.style, {
    position: "fixed", bottom: "16px", right: "16px", zIndex: 99999,
    padding: "10px 14px", background: "#261FFF", color: "#fff",
    border: "none", borderRadius: "8px", fontSize: "14px", cursor: "pointer",
    boxShadow: "0 2px 8px rgba(0,0,0,0.3)",
  });
  btn.addEventListener("click", () => {
    btn.disabled = true;
    btn.textContent = "Importing…";
    importRound().finally(() => {
      btn.disabled = false;
      btn.textContent = "⚽ Import round → Mantra";
    });
  });
  document.body.appendChild(btn);
}

addButton();
