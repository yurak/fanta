import { useMemo } from "react";
import { ILeagueFantaResults } from "../../../../../interfaces/LeagueResults";
import Table from "../../../../../ui/Table";
import { useHistorySort } from "../../../../../hooks/useHistorySort";

import styles from "./LeagueResultsFantaTable.module.scss";

const LeagueResultsFantaTable = ({
  leaguesResults,
  isLoading,
}: {
  leaguesResults: ILeagueFantaResults[],
  isLoading: boolean,
}) => {
  const dataSource = useMemo(() => {
    return leaguesResults.map((teamResult, index) => {
      return {
        ...teamResult,
        position: index + 1,
      };
    });
  }, [leaguesResults]);

  const historySort = useHistorySort();

  return (
    <Table
      dataSource={dataSource}
      isLoading={isLoading}
      skeletonItems={8}
      sorting={historySort}
      columns={[
        {
          dataKey: "position",
          align: "center",
          render: ({ position }) => {
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
            compare: (teamA, teamB) => teamA.team.human_name.localeCompare(teamB.team.human_name),
          },
          render: ({ team }) => (
            <a href={`/teams/${team.id}`} className={styles.teamName}>
              <span className={styles.teamNameImg}>
                <img src={team.logo_path} />
              </span>
              <span className={styles.teamNameName}>{team.human_name}</span>
            </a>
          ),
        },
        {
          dataKey: "matches_played",
          title: (
            <>
              <span className={styles.fullTitle}>Played</span>
              <span className={styles.shortTitle}>PL</span>
            </>
          ),
          align: "right",
          className: styles.stats,
        },
        {
          dataKey: "points",
          title: (
            <>
              <span className={styles.fullTitle}>F1 Points</span>
              <span className={styles.shortTitle}>F1</span>
            </>
          ),
          align: "right",
          className: styles.stats,
          sorter: {
            compare: (teamA, teamB) => teamB.points - teamA.points,
          },
        },
        {
          dataKey: "total_score",
          title: (
            <>
              <span className={styles.fullTitle}>Total score</span>
              <span className={styles.shortTitle}>TS</span>
            </>
          ),
          align: "right",
          className: styles.stats,
          sorter: {
            compare: (teamA, teamB) => Number(teamB.total_score) - Number(teamA.total_score),
          },
        },
        {
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
            compare: (teamA, teamB) => Number(teamB.best_lineup) - Number(teamA.best_lineup),
          },
        },
      ]}
    />
  );
};

export default LeagueResultsFantaTable;
