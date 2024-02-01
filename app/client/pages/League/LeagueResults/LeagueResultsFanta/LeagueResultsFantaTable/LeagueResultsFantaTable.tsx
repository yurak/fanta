import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import cn from "classnames";
import { ILeagueFantaResults } from "../../../../../interfaces/LeagueResults";
import Table from "../../../../../ui/Table";
import TeamName, { TeamNameSkeleton } from "../../../../../components/TeamName";
import { useHistorySort } from "../../../../../hooks/useHistorySort";
import { sorters } from "../../../../../helpers/sorters";
import styles from "./LeagueResultsFantaTable.module.scss";

const LeagueResultsFantaTable = ({
  leaguesResults,
  isLoading,
}: {
  leaguesResults: ILeagueFantaResults[],
  isLoading: boolean,
}) => {
  const historySort = useHistorySort();
  const { t } = useTranslation();

  const data = useMemo(() => {
    return leaguesResults.map((item) => ({
      ...item,
      teamName: item.team.human_name,
    }));
  }, [leaguesResults]);

  return (
    <Table
      dataSource={data}
      isLoading={isLoading}
      skeletonItems={8}
      sorting={historySort}
      columns={[
        {
          dataKey: "position",
          align: "center",
          noWrap: true,
          render: (_, index) => {
            const position = index + 1;

            if (position === 1) {
              return <>🥇</>;
            }

            if (position === 2) {
              return <>🥈</>;
            }

            if (position === 3) {
              return <>🥉</>;
            }

            return <>{position}</>;
          },
          className: styles.position,
        },
        {
          dataKey: "team",
          title: t("table.team"),
          className: styles.team,
          sorter: {
            compare: sorters.string("teamName"),
          },
          render: ({ team }) => <TeamName team={team} />,
          skeleton: <TeamNameSkeleton />,
        },
        {
          dataKey: "matches_played",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.games")}</span>
              <span className={styles.shortTitle}>{t("table.games_short")}</span>
            </>
          ),
          noWrap: true,
          align: "right",
          className: styles.played,
        },
        {
          dataKey: "points",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.f1_points")}</span>
              <span className={styles.shortTitle}>F1</span>
            </>
          ),
          noWrap: true,
          align: "right",
          className: styles.stats,
          sorter: {
            compare: sorters.numbers("points"),
          },
        },
        {
          key: "score",
          dataKey: "total_score",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.total_score")}</span>
              <span className={styles.shortTitle}>{t("table.total_score_short")}</span>
            </>
          ),
          noWrap: true,
          align: "right",
          className: cn(styles.stats, styles.bold),
          sorter: {
            compare: sorters.numbers("total_score", true),
          },
        },
        {
          key: "lineup",
          dataKey: "best_lineup",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.best_lineup")}</span>
              <span className={styles.shortTitle}>{t("table.best_lineup_short")}</span>
            </>
          ),
          align: "right",
          className: styles.stats,
          sorter: {
            compare: sorters.numbers("best_lineup", true),
          },
        },
      ]}
    />
  );
};

export default LeagueResultsFantaTable;
