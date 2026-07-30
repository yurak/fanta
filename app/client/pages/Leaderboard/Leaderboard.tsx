import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import cn from "classnames";
import PageLayout from "@/layouts/PageLayout";
import Heading from "@/components/Heading";
import Tabs, { ITab } from "@/ui/Tabs";
import Switcher from "@/ui/Switcher";
import EmptyState from "@/ui/EmptyState";
import InfinityScrollDetector from "@/components/InfinityScrollDetector";
import { LeaderboardMetric } from "@/interfaces/Leaderboard";
import { useLeaderboard } from "@/api/query/useLeaderboard";
import LeaderCard from "./LeaderCard";
import CurrentUserCard from "./CurrentUserCard";
import TournamentFilter from "./TournamentFilter";
import LeaderboardRow from "./LeaderboardRow";
import styles from "./Leaderboard.module.scss";

interface MetricTab extends ITab<LeaderboardMetric> {
  short: string,
}

const VALUE_COLUMN_KEY: Record<LeaderboardMetric, string> = {
  win_rate: "leaderboard.col_win_rate",
  avg_total_score: "leaderboard.col_avg_total_score",
  titles: "leaderboard.col_titles",
  matches: "leaderboard.col_matches",
};

const VALUE_SHORT_KEY: Record<LeaderboardMetric, string> = {
  win_rate: "leaderboard.col_win_rate_short",
  avg_total_score: "leaderboard.col_avg_total_score_short",
  titles: "leaderboard.col_titles_short",
  matches: "leaderboard.col_matches_short",
};

const SECONDARY_COLUMN_KEY: Partial<Record<LeaderboardMetric, string>> = {
  win_rate: "leaderboard.col_matches",
  avg_total_score: "leaderboard.col_matches",
  titles: "leaderboard.col_champion_number",
};

const SECONDARY_SHORT_KEY: Partial<Record<LeaderboardMetric, string>> = {
  win_rate: "leaderboard.col_matches_short",
  avg_total_score: "leaderboard.col_matches_short",
  titles: "leaderboard.col_champion_number_short",
};

const MIN_MATCHES = 100;

// Time-period filters are not implemented yet — kept in code, hidden for now.
const SHOW_PERIODS = false;

const Leaderboard = () => {
  const { t } = useTranslation();
  const [metric, setMetric] = useState<LeaderboardMetric>("win_rate");
  const [onlyExperienced, setOnlyExperienced] = useState(false);
  const [tournamentId, setTournamentId] = useState<number | null>(null);

  const metricTabs: MetricTab[] = [
    { id: "win_rate", name: `🥇 ${t("leaderboard.tab_win_rate")}`, short: `🥇 ${t("leaderboard.tab_win_rate_short")}` },
    { id: "avg_total_score", name: `🎲 ${t("leaderboard.tab_avg_total_score")}`, short: `🎲 ${t("leaderboard.tab_avg_total_score_short")}` },
    { id: "titles", name: `🏆 ${t("leaderboard.tab_titles")}`, short: `🏆 ${t("leaderboard.tab_titles_short")}` },
    { id: "matches", name: `⚽ ${t("leaderboard.tab_matches")}`, short: `⚽ ${t("leaderboard.tab_matches_short")}` },
  ];

  const secondaryKey = SECONDARY_COLUMN_KEY[metric];
  const secondaryShortKey = SECONDARY_SHORT_KEY[metric];

  const renderHeader = (fullKey: string, shortKey: string) => (
    <>
      <span className={styles.thFull}>{t(fullKey)}</span>
      <span className={styles.thShort}>{t(shortKey)}</span>
    </>
  );

  const query = useLeaderboard({
    metric,
    includeNewbies: false,
    minMatches: onlyExperienced ? MIN_MATCHES : 0,
    tournamentId,
  });

  const entries = useMemo(
    () => query.data?.pages.flatMap((page) => page.data) ?? [],
    [query.data]
  );
  const currentUser = query.data?.pages[0]?.meta.current_user ?? null;

  const loadMore = () => {
    if (query.hasNextPage && !query.isFetchingNextPage) {
      query.fetchNextPage();
    }
  };

  return (
    <PageLayout>
      <div className={styles.pageHeading}>
        <Heading title={t("leaderboard.title")} description={t("leaderboard.subtitle")} />
      </div>

      <div className={styles.controls}>
        <Tabs
          tabs={metricTabs}
          active={metric}
          onChange={setMetric}
          nameRender={(tab) => (
            <>
              <span className={styles.tabFull}>{tab.name}</span>
              <span className={styles.tabShort}>{tab.short}</span>
            </>
          )}
        />
        <div className={styles.filters}>
          {SHOW_PERIODS && (
            <div className={styles.periods}>
              <button type="button" className={cn(styles.period, styles.periodActive)}>
                {t("leaderboard.period_all_time")}
              </button>
              <button type="button" className={styles.period} disabled title={t("leaderboard.soon")}>
                {t("leaderboard.period_last_30_days")}
              </button>
              <button type="button" className={styles.period} disabled title={t("leaderboard.soon")}>
                {t("leaderboard.period_last_year")}
              </button>
            </div>
          )}
          <Switcher
            checked={onlyExperienced}
            onChange={setOnlyExperienced}
            label={t("leaderboard.matches_100")}
          />
          <div className={styles.tournamentSelect}>
            <TournamentFilter value={tournamentId} onChange={setTournamentId} />
          </div>
        </div>
      </div>

      <div className={styles.content}>
        <div className={styles.aside}>
          <LeaderCard entry={entries[0]} metric={metric} />
          {currentUser && currentUser.rank !== 1 && (
            <CurrentUserCard entry={currentUser} metric={metric} />
          )}
        </div>

        <div
          className={cn(styles.table, {
            [styles.tableTitles]: metric === "titles",
            [styles.tableMatches]: metric === "matches",
          })}
        >
          <div className={cn(styles.row, styles.headRow)}>
            <div className={cn(styles.cell, styles.placeCell)}>
              {renderHeader("leaderboard.col_place", "leaderboard.col_place_short")}
            </div>
            <div className={cn(styles.cell, styles.managerCell)}>{t("leaderboard.col_manager")}</div>
            {secondaryKey && secondaryShortKey && (
              <div className={cn(styles.cell, styles.secondaryCell)}>
                {renderHeader(secondaryKey, secondaryShortKey)}
              </div>
            )}
            <div className={cn(styles.cell, styles.valueCell)}>
              {renderHeader(VALUE_COLUMN_KEY[metric], VALUE_SHORT_KEY[metric])}
            </div>
          </div>

          {entries.length === 0 && !query.isPending ? (
            <EmptyState title={t("leaderboard.empty")} />
          ) : (
            entries.map((entry) => (
              <LeaderboardRow
                key={entry.id}
                entry={entry}
                metric={metric}
                highlighted={entry.id === currentUser?.id}
              />
            ))
          )}

          {query.hasNextPage && <InfinityScrollDetector loadMore={loadMore} />}
        </div>
      </div>
    </PageLayout>
  );
};

export default Leaderboard;
