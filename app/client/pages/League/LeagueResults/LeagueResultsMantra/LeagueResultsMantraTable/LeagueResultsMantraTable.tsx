import { useMemo } from "react";
import cn from "classnames";
import { ILeagueResults } from "../../../../../interfaces/LeagueResults";
import Table from "../../../../../ui/Table";

import styles from "./LeagueResultsMantraTable.module.scss";

const LeagueResultsMantraTable = ({
  leaguesResults,
  isLoading,
  promotion,
  relegation,
  teamsCount,
}: {
  leaguesResults: ILeagueResults[];
  isLoading: boolean;
  promotion: number;
  relegation: number;
  teamsCount: number;
}) => {
  const dataSource = useMemo(() => {
    return leaguesResults.map((item, index) => {
      return {
        ...item,
        position: index + 1,
      };
    });
  }, [leaguesResults]);

  return (
    <Table
      dataSource={dataSource}
      isLoading={isLoading}
      skeletonItems={8}
      rowLink={({ team }) => `/teams/${team.id}`}
      defaultSortColumn="points"
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
          dataClassName: (item) =>
            cn(styles.position, {
              [styles.isPromotion]: item && item.position <= promotion,
              [styles.isRelegation]: item && item.position > teamsCount - relegation,
            }),
        },
        {
          dataKey: "team",
          title: "Team",
          className: styles.team,
          sorter: (teamA, teamB) => teamA.team.human_name.localeCompare(teamB.team.human_name),
          render: ({ team }) => (
            <span className={styles.teamName}>
              <span className={styles.teamNameImg}>
                <img src={team.logo_path} />
              </span>
              <span className={styles.teamNameName}>{team.human_name}</span>
            </span>
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
          sorter: (teamA, teamB) => teamB.wins - teamA.wins,
        },
        {
          dataKey: "draws",
          title: "Draws",
          align: "right",
          className: styles.games,
          sorter: (teamA, teamB) => teamB.draws - teamA.draws,
        },
        {
          dataKey: "loses",
          title: "Loses",
          align: "right",
          className: styles.games,
          sorter: (teamA, teamB) => teamB.loses - teamA.loses,
        },
        {
          dataKey: "scored_goals",
          title: "GF",
          align: "right",
          className: styles.goals,
          sorter: (teamA, teamB) => teamB.scored_goals - teamA.scored_goals,
        },
        {
          dataKey: "missed_goals",
          title: "GA",
          align: "right",
          className: styles.goals,
          sorter: (teamA, teamB) => teamB.missed_goals - teamA.missed_goals,
        },
        {
          dataKey: "goals_difference",
          title: "GD",
          align: "right",
          className: styles.goals,
          sorter: (teamA, teamB) => teamB.goals_difference - teamA.goals_difference,
        },
        {
          dataKey: "points",
          title: "Points",
          align: "right",
          className: styles.points,
          dataClassName: styles.pointsData,
          sorter: (teamA, teamB) => teamB.points - teamA.points,
        },
        {
          dataKey: "total_score",
          title: "TS",
          align: "right",
          className: styles.points,
          sorter: (teamA, teamB) => Number(teamB.total_score) - Number(teamA.total_score),
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
          sorter: (itemA, itemB) => {
            const teamAPoints = itemA.form.reduce((totalPoints, form) => {
              const point = (form === "D" && 1) || (form === "W" && 3) || 0;

              return totalPoints + point;
            }, 0);

            const teamBPoints = itemB.form.reduce((totalPoints, form) => {
              const point = (form === "D" && 1) || (form === "W" && 3) || 0;

              return totalPoints + point;
            }, 0);

            return teamBPoints - teamAPoints;
          },
        },
        {
          dataKey: "next",
          title: "Next",
          className: styles.next,
          render: ({ next_opponent_id }) => {
            const opponent = leaguesResults.find(({ team }) => team.id === next_opponent_id)?.team;

            if (!opponent) {
              return null;
            }

            return (
              <div className={styles.opponent}>
                <img src={opponent.logo_path} />
              </div>
            );
          },
        },
      ]}
    />
  );
};

export default LeagueResultsMantraTable;
