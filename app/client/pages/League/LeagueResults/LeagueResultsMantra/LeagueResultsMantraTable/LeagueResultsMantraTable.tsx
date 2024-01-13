import { useMemo } from "react";
import cn from "classnames";
import { ILeagueResults, ILeagueResultsHistory } from "../../../../../interfaces/LeagueResults";
import Table from "../../../../../ui/Table";
import TriangleDownIcon from "../../../../../assets/icons/triangleDown.svg";

import styles from "./LeagueResultsMantraTable.module.scss";

const getPositionUpdate = (teamResult: ILeagueResults): null | "top" | "down" => {
  const { history } = teamResult;
  const existHistory = history.filter(Boolean) as ILeagueResultsHistory[];
  const currentPosition = existHistory[existHistory.length - 1]?.pos;
  const prevPosition = existHistory[existHistory.length - 2]?.pos;

  if (!(currentPosition && prevPosition)) {
    return null;
  }

  if (currentPosition < prevPosition) {
    return "top";
  }

  if (currentPosition > prevPosition) {
    return "down";
  }

  return null;
};

const LeagueResultsMantraTable = ({
  leaguesResults,
  isLoading,
  promotion,
  relegation,
  teamsCount,
}: {
  leaguesResults: ILeagueResults[],
  isLoading: boolean,
  promotion: number,
  relegation: number,
  teamsCount: number,
}) => {
  const dataSource = useMemo(() => {
    return leaguesResults.map((teamResult, index) => {
      return {
        ...teamResult,
        total_score: Number(teamResult.total_score),
        formPoints: teamResult.form
          .map((form) => (form === "W" && 3) || (form === "D" && 1) || 0)
          .reduce((totalPoints, point) => totalPoints + point, 0),
        position: index + 1,
        positionUpdate: getPositionUpdate(teamResult),
      };
    });
  }, [leaguesResults]);

  return (
    <Table
      dataSource={dataSource}
      isLoading={isLoading}
      skeletonItems={8}
      tableClassName={styles.table}
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
          dataKey: "positionUpdate",
          align: "center",
          className: styles.positionUpdate,
          render: ({ positionUpdate }) =>
            positionUpdate ? (
              <TriangleDownIcon
                className={cn(styles.positionUpdateIcon, {
                  [styles.top]: positionUpdate === "top",
                  [styles.down]: positionUpdate === "down",
                })}
              />
            ) : (
              <span className={styles.positionUpdateNoChange} />
            ),
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
          className: styles.matchesPlayed,
        },
        {
          dataKey: "wins",
          title: (
            <>
              <span className={styles.fullTitle}>Wins</span>
              <span className={styles.shortTitle}>W</span>
            </>
          ),
          align: "right",
          className: styles.matchesWins,
          sorter: {
            compare: (teamA, teamB) => teamB.wins - teamA.wins,
            priority: 3,
          },
        },
        {
          dataKey: "draws",
          title: (
            <>
              <span className={styles.fullTitle}>Draws</span>
              <span className={styles.shortTitle}>D</span>
            </>
          ),
          align: "right",
          className: styles.matchesDraws,
          sorter: {
            compare: (teamA, teamB) => teamB.draws - teamA.draws,
          },
        },
        {
          dataKey: "loses",
          title: (
            <>
              <span className={styles.fullTitle}>Loses</span>
              <span className={styles.shortTitle}>L</span>
            </>
          ),
          align: "right",
          className: styles.matchesLoses,
          sorter: {
            compare: (teamA, teamB) => teamB.loses - teamA.loses,
          },
        },
        {
          dataKey: "scored_goals",
          title: "GF",
          align: "right",
          className: styles.goals,
          sorter: {
            compare: (teamA, teamB) => teamB.scored_goals - teamA.scored_goals,
            priority: 2,
          },
        },
        {
          dataKey: "missed_goals",
          title: "GA",
          align: "right",
          className: styles.goals,
          sorter: {
            compare: (teamA, teamB) => teamB.missed_goals - teamA.missed_goals,
          },
        },
        {
          dataKey: "goals_difference",
          title: "GD",
          align: "right",
          className: styles.goals,
          sorter: {
            compare: (teamA, teamB) => teamB.goals_difference - teamA.goals_difference,
          },
        },
        {
          dataKey: "points",
          title: (
            <>
              <span className={styles.fullTitle}>Points</span>
              <span className={styles.shortTitle}>PTS</span>
            </>
          ),
          align: "right",
          className: styles.points,
          dataClassName: styles.pointsData,
          sorter: {
            compare: (teamA, teamB) => teamB.points - teamA.points,
            priority: 1,
          },
        },
        {
          dataKey: "total_score",
          title: "TS",
          align: "right",
          className: styles.totalScore,
          sorter: {
            compare: (teamA, teamB) => teamB.total_score - teamA.total_score,
            priority: 4,
          },
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
          sorter: {
            compare: (itemA, itemB) => itemB.formPoints - itemA.formPoints,
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
              <a href={`/teams/${opponent.id}`} className={styles.opponent}>
                <img src={opponent.logo_path} />
              </a>
            );
          },
        },
      ]}
    />
  );
};

export default LeagueResultsMantraTable;
