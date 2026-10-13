import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import cn from "classnames";
import { useDivisions } from "@/api/query/useDivisions";
import { useTournaments } from "@/api/query/useTournaments";
import { ISeason } from "@/interfaces/Season";
import { ITournament } from "@/interfaces/Tournament";
import SeasonsSelect from "@/components/SeasonsSelect";
import TournamentSelect from "@/components/TournamentSelect";
import EyeIcon from "@/assets/icons/eye.svg";
import EyeOffIcon from "@/assets/icons/eye-off.svg";
import LeagueCard from "./LeagueCard";
import styles from "./Divisions.module.scss";

// Divisions are a mantra thing: every tournament that has them is in mantra mode, and picking a
// fanta one from the list would only ever open an empty page.
const isMantra = (tournament: ITournament) => tournament.mantra_format;

const Divisions = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const params = useParams<{ tournamentId: string }>();
  const tournamentId = Number(params.tournamentId);

  const [season, setSeason] = useState<ISeason | null>(null);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});

  // The URL owns the tournament; the select merely reflects it. Holding it in state as well let
  // the select pick the first option before the list had been matched against the address, and
  // /tournaments/4/divisions bounced to /tournaments/1/divisions on open.
  const { data: tournaments } = useTournaments();
  const tournament = useMemo(
    () => (tournaments ?? []).find((option) => option.id === tournamentId) ?? null,
    [tournaments, tournamentId]
  );

  const { data } = useDivisions(tournamentId, season?.id);
  const levels = data?.data ?? [];
  const meta = data?.meta;

  const selectTournament = (next: ITournament) => {
    if (next.id !== tournamentId) {
      navigate(`/tournaments/${next.id}/divisions`);
    }
  };

  // Collapsed levels are keyed by their letter, and letters repeat across tournaments: without
  // this, collapsing A-D here and switching to a competition with six levels left A-D shut and
  // E-F open. The state belongs to the table on screen, so it goes when the table does.
  useEffect(() => {
    setCollapsed({});
  }, [tournamentId, season?.id]);

  const allCollapsed = useMemo(
    () => levels.length > 0 && levels.every((level) => collapsed[level.level]),
    [levels, collapsed]
  );

  const toggleAll = () => {
    setCollapsed(allCollapsed ? {} : Object.fromEntries(levels.map(({ level }) => [level, true])));
  };

  return (
    <div className={cn("page-info", styles.page)}>
      <div className={styles.head}>
        <h1 className={styles.title}>{t("divisions.title")}</h1>
        <div className={styles.selects}>
          <div className={styles.tournamentSelect}>
            <TournamentSelect value={tournament} onChange={selectTournament} filter={isMantra} />
          </div>
          <div className={styles.seasonSelect}>
            <SeasonsSelect value={season} onChange={setSeason} />
          </div>
        </div>
        <button type="button" className={styles.toggleAll} onClick={toggleAll}>
          {allCollapsed ? t("divisions.expand_all") : t("divisions.collapse_all")}
        </button>
      </div>

      {levels.map((level, levelIndex) => {
        const isCollapsed = Boolean(collapsed[level.level]);
        const holdsMyLeague = level.leagues.some((league) => meta?.my_league_ids.includes(league.id));

        return (
          <div key={level.id} className={styles.level}>
            <div className={styles.rail}>
              <div
                className={cn(styles.levelBadge, {
                  [styles.levelBadgeCollapsed]: isCollapsed,
                  [styles.levelBadgeMine]: holdsMyLeague,
                })}
              >
                <span className={styles.levelLetter}>{level.level}</span>
                <span className={styles.levelCount}>({level.leagues.length})</span>
              </div>
              {/* before the toggle so a narrow screen keeps it beside the badge; on desktop the
                  eye is positioned onto the rail line and DOM order does not matter */}
              <button
                type="button"
                className={styles.eye}
                aria-label={isCollapsed ? t("divisions.expand_all") : t("divisions.collapse_all")}
                onClick={() =>
                  setCollapsed((current) => ({ ...current, [level.level]: !current[level.level] }))
                }
              >
                {isCollapsed ? <EyeIcon /> : <EyeOffIcon />}
              </button>
              {levelIndex === 0 && (
                <button type="button" className={styles.toggleAllInline} onClick={toggleAll}>
                  {allCollapsed ? t("divisions.expand_all") : t("divisions.collapse_all")}
                </button>
              )}
            </div>

            <div className={styles.cards}>
              {level.leagues.map((league) => (
                <LeagueCard
                  key={league.id}
                  league={league}
                  collapsed={isCollapsed}
                  isMine={Boolean(meta?.my_league_ids.includes(league.id))}
                  myTeamIds={meta?.my_team_ids ?? []}
                />
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default Divisions;
