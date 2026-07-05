import { useTranslation } from "react-i18next";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { ISeasonStat } from "@/interfaces/PlayerStats";
import DefaultLogo from "@/assets/icons/noTeam.svg";
import styles from "./PlayerPage.module.scss";

const GK_KEYS: [keyof ISeasonStat, string][] = [
  ["missed_goals", "mg"],
  ["missed_penalty", "mp"],
  ["caught_penalty", "cp"],
  ["saves", "s"],
];

const OUTFIELD_KEYS: [keyof ISeasonStat, string][] = [
  ["goals", "g"],
  ["scored_penalty", "sp"],
  ["failed_penalty", "fp"],
  ["penalties_won", "ep"],
];

const COMMON_KEYS: [keyof ISeasonStat, string][] = [
  ["assists", "as"],
  ["yellow_card", "yc"],
  ["red_card", "rc"],
  ["cleansheet", "cs"],
  ["own_goals", "og"],
  ["conceded_penalty", "pf"],
];

const seasonLabel = (stat: ISeasonStat) =>
  stat.season ? `${stat.season.start_year}-${stat.season.end_year}` : `#${stat.season_id}`;

const PlayerSeasonStats = ({
  isGoalkeeper,
  seasonStats,
}: {
  isGoalkeeper: boolean,
  seasonStats: ISeasonStat[],
}) => {
  const { t } = useTranslation();

  if (seasonStats.length === 0) {
    return null;
  }

  const statKeys = [...(isGoalkeeper ? GK_KEYS : OUTFIELD_KEYS), ...COMMON_KEYS];

  return (
    <div className={`${styles.table} ${styles.perfTable}`}>
      <div className={styles.tableTitle}>{t("players.stats")}</div>

      <div className={styles.perfTableWrap}>
        <div className={styles.seasonInner}>
          <div className={`${styles.perfRow} ${styles.seasonStatsRow} ${styles.perfHeaders}`}>
            <div className={styles.headerCell}>{t("players.season")}</div>
            <div className={styles.headerCell}>{t("players.club")}</div>
            <div className={styles.headerCell}>{t("players.positions")}</div>
            <div className={styles.headerCell} title={t("players.played_matches")}>{t("players.pma")}</div>
            {statKeys.map(([key, header]) => (
              <div key={key} className={styles.headerCell} title={t(`players.${header}`)}>
                {t(`players.${header}`)}
              </div>
            ))}
            <div className={styles.headerCell} title={t("players.played_minutes")}>{t("players.pm")}</div>
            <div className={styles.headerCell} title={t("players.sixties")}>60&apos;+</div>
            <div className={styles.headerCell} title={t("players.base_score")}>{t("players.bs")}</div>
            <div className={styles.headerCell} title={t("players.total_score")}>{t("players.ts")}</div>
          </div>

          {seasonStats.map((stat) => (
            <div key={stat.id} className={`${styles.perfRow} ${styles.seasonStatsRow} ${styles.dataRow}`}>
              <div className={styles.cell}>{seasonLabel(stat)}</div>
              <div className={`${styles.cell} ${styles.statsClub}`}>
                <object data={stat.club_logo_path ?? undefined} type="image/png">
                  <DefaultLogo />
                </object>
              </div>
              <div className={`${styles.cell} ${styles.statsPositions}`}>
                <PlayerPositions position={stat.position_classic_arr} />
              </div>
              <div className={styles.cell}>{stat.played_matches}</div>
              {statKeys.map(([key]) => (
                <div key={key} className={styles.cell}>{Number(stat[key])}</div>
              ))}
              <div className={styles.cell}>{stat.played_minutes}</div>
              <div className={styles.cell}>{stat.sixties}</div>
              <div className={`${styles.cell} ${styles.ts}`}>{stat.base_score}</div>
              <div className={`${styles.cell} ${styles.ts}`}>{stat.total_score}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default PlayerSeasonStats;
