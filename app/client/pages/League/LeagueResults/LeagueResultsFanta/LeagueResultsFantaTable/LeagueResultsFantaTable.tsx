import { useMemo } from "react";
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
          title: "Team",
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
              <span className={styles.fullTitle}>Played</span>
              <span className={styles.shortTitle}>PL</span>
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
              <span className={styles.fullTitle}>F1 Points</span>
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
              <span className={styles.fullTitle}>Total score</span>
              <span className={styles.shortTitle}>TS</span>
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
              <span className={styles.fullTitle}>Best lineup</span>
              <span className={styles.shortTitle}>Best</span>
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
