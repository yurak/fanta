// ==UserScript==
// @name         MantraFootball — SofaScore round importer
// @namespace    mantrafootball
// @version      1.3.0
// @description  Fetches SofaScore event + lineups + incidents JSON from the browser and sends a whole round to MantraFootball (bypasses the server-side block).
// @match        https://www.sofascore.com/*
// @connect      www.sofascore.com
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
 *   enter the Mantra tournament_round id -- that is the only thing to type. The script
 *   asks Mantra which SofaScore event ids belong to that round, which round it is and the
 *   "uniqueTournament-season" pair (kept in the tournament's sofa_number, e.g. UPL 2026/27
 *   = 218-97214), reads that round from SofaScore, fetches lineups + incidents per match,
 *   posts everything back, and Mantra injects the scores automatically.
 *
 * What each source gives Mantra:
 *   round     — the event of each match: final score and whether it is finished
 *   lineups   — per-player minutes, rating, goals, assists, saves, penalty stats
 *   incidents — cards and which goals came from the spot
 */

const MANTRA_BASE = "https://mantrafootball.org";
const INGEST_TOKEN = "PASTE_SOFASCORE_INGEST_TOKEN_HERE";

const SOFA_API = "https://www.sofascore.com/api/v1/event";
const SOFA_ROUND = "https://www.sofascore.com/api/v1/unique-tournament";
const DEFAULT_UT_SEASON = "218-97214"; // UPL 2026/27

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
  const res = await gmRequest({ method: "GET", url });
  if (res.status < 200 || res.status >= 300) {
    throw new Error(`SofaScore ${res.status} for ${url}`);
  }
  return res.responseText;
}

async function mantraRound(roundId) {
  const res = await gmRequest({
    method: "GET",
    url: `${MANTRA_BASE}/api/sofascore/matches?tournament_round_id=${encodeURIComponent(roundId)}`,
    headers: { "X-Ingest-Token": INGEST_TOKEN },
  });
  if (res.status !== 200) throw new Error(`Mantra list ${res.status}: ${res.responseText}`);
  return JSON.parse(res.responseText);
}

async function roundEvents(ut, season, round) {
  const url = `${SOFA_ROUND}/${ut}/season/${season}/events/round/${round}`;
  const events = JSON.parse(await fetchText(url)).events || [];
  return new Map(events.map((e) => [String(e.id), e]));
}

async function fetchOptionalText(url) {
  try {
    return await fetchText(url);
  } catch (e) {
    console.warn(`Mantra importer: no incidents for ${url} (${e.message})`);
    return null;
  }
}

async function importMatch(sofaId, event) {
  if (!event) throw new Error(`event ${sofaId} is not in that round on SofaScore`);

  const baseData = JSON.stringify({ event });
  const lineupsData = await fetchText(`${SOFA_API}/${sofaId}/lineups`);
  const incidentsData = await fetchOptionalText(`${SOFA_API}/${sofaId}/incidents`);

  const res = await gmRequest({
    method: "POST",
    url: `${MANTRA_BASE}/api/sofascore/matches`,
    headers: { "X-Ingest-Token": INGEST_TOKEN, "Content-Type": "application/json" },
    data: JSON.stringify({
      sofascore_id: sofaId,
      base_data: baseData,
      lineups_data: lineupsData,
      incidents_data: incidentsData,
    }),
  });
  return { sofaId, status: res.status, body: res.responseText };
}

async function importRound() {
  const roundId = prompt("Mantra tournament_round id for this UPL round:");
  if (!roundId) return;

  let mantra;
  try {
    mantra = await mantraRound(roundId.trim());
  } catch (e) {
    alert(`Could not read round from Mantra:\n${e.message}`);
    return;
  }
  const sofaIds = mantra.data;
  if (!sofaIds.length) {
    alert("No matches with a source_match_id in that round.");
    return;
  }

  const pair =
    mantra.ut_season || prompt('SofaScore "uniqueTournament-season" pair:', DEFAULT_UT_SEASON);
  if (!pair) return;
  const [ut, season] = pair.trim().split("-");

  let events;
  try {
    events = await roundEvents(ut, season, mantra.round);
  } catch (e) {
    alert(`Could not read round ${mantra.round} from SofaScore:\n${e.message}`);
    return;
  }

  const results = [];
  for (const sofaId of sofaIds) {
    try {
      results.push(await importMatch(sofaId, events.get(String(sofaId))));
    } catch (e) {
      results.push({ sofaId, status: "error", body: e.message });
    }
  }

  const ok = results.filter((r) => r.status === 200).length;
  const lines = results
    .map((r) => `${r.sofaId}: ${r.status}${r.status === 200 ? "" : ` — ${r.body}`}`)
    .join("\n");
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
