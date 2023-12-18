import cn from "classnames";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import Table from "../../../../ui/Table";

import styles from "./LeaguesResultsTable.module.scss";
import TeamLoader from "./TeamLoader";

const LeaguesResultsTable = ({
  leagueId,
  promotion,
  relegation,
  teamsCount,
}: {
  leagueId: number;
  promotion: number;
  relegation: number;
  teamsCount: number;
}) => {
  const leaguesResults = useLeagueResults(leagueId);

  return (
    <Table
      dataSource={leaguesResults.data}
      isLoading={leaguesResults.isLoading}
      skeletonItems={8}
      rowLink={({ team_id }) => `/teams/${team_id}`}
      columns={[
        {
          dataKey: "position",
          align: "center",
          render: (_, rowIndex) => {
            const position = rowIndex + 1;

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
          dataClassName: (_, rowIndex) =>
            cn(styles.position, {
              [styles.isPromotion]: rowIndex < promotion,
              [styles.isRelegation]: rowIndex >= teamsCount - relegation,
            }),
        },
        {
          dataKey: "team",
          title: "Team",
          className: styles.team,
          render: ({ team_id }) => (
            <TeamLoader teamId={team_id}>
              {(team) => (
                <span className={styles.teamName}>
                  <span className={styles.teamNameImg}>
                    <img src={team.logo_path} />
                  </span>
                  <span className={styles.teamNameName}>{team.human_name}</span>
                </span>
              )}
            </TeamLoader>
          ),
        },
        {
          dataKey: "matches_played",
          title: "Games",
          align: "right",
          className: styles.games,
        },
        {
          dataKey: "wins",
          title: "Wins",
          align: "right",
          className: styles.games,
        },
        {
          dataKey: "draws",
          title: "Draws",
          align: "right",
          className: styles.games,
        },
        {
          dataKey: "loses",
          title: "Loses",
          align: "right",
          className: styles.games,
        },
        {
          dataKey: "scored_goals",
          title: "GF",
          align: "right",
          className: styles.goals,
        },
        {
          dataKey: "missed_goals",
          title: "GA",
          align: "right",
          className: styles.goals,
        },
        {
          dataKey: "goals_difference",
          title: "GD",
          align: "right",
          className: styles.goals,
        },
        {
          dataKey: "points",
          title: "Points",
          align: "right",
          className: styles.points,
          dataClassName: styles.pointsData,
        },
        {
          dataKey: "total_score",
          title: "TS",
          align: "right",
          className: styles.points,
        },
        {
          dataKey: "form",
          title: "Form",
          render: ({ form }) => (
            <span className={styles.formData}>
              {form.map((state, index) => (
                <span
                  key={index}
                  className={cn({
                    [styles.formWin]: state === "W",
                    [styles.formLose]: state === "L",
                    [styles.formDraw]: state === "D",
                  })}
                >
                  {state}
                </span>
              ))}
            </span>
          ),
          className: styles.form,
        },
        {
          dataKey: "next",
          title: "Next",
          className: styles.next,
          render: ({ next_opponent_id }) => (
            <TeamLoader teamId={next_opponent_id}>
              {(team) => (
                <div className={styles.opponent}>
                  <img src={team.logo_path} />
                </div>
              )}
            </TeamLoader>
          ),
        },
      ]}
    />
  );
};

export default LeaguesResultsTable;
