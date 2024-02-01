import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import cn from "classnames";
import { ILeagueResults, ILeagueResultsHistory } from "../../../../../interfaces/LeagueResults";
import Table from "../../../../../ui/Table";
import TriangleDownIcon from "../../../../../assets/icons/triangleDown.svg";
import { sorters } from "../../../../../helpers/sorters";
import styles from "./LeagueResultsMantraTable.module.scss";
import TeamName, { TeamNameSkeleton } from "../../../../../components/TeamName";

const getPositionUpdate = ({ history }: ILeagueResults): null | "top" | "down" => {
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

const getFormPoints = (form: ILeagueResults["form"]) => {
  return form
    .map((form) => (form === "W" && 3) || (form === "D" && 1) || 0)
    .reduce((totalPoints, point) => totalPoints + point, 0);
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
  const { t } = useTranslation();

  const dataSource = useMemo(
    () =>
      leaguesResults.map((teamResult, index) => ({
        ...teamResult,
        teamName: teamResult.team.human_name,
        formPoints: getFormPoints(teamResult.form),
        position: index + 1,
        positionUpdate: getPositionUpdate(teamResult),
      })),
    [leaguesResults]
  );

  return (
    <Table
      dataSource={dataSource}
      isLoading={isLoading}
      skeletonItems={8}
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
          key: "mobileTeamLogo",
          className: styles.teamLogoCell,
          headClassName: styles.teamLogoHeadCell,
          sticky: true,
          render: ({ team }) => <TeamName team={team} hideName />,
          skeleton: <TeamNameSkeleton hideName />,
        },
        {
          dataKey: "team",
          title: t("table.team"),
          className: styles.team,
          headClassName: styles.teamHeadCell,
          sorter: {
            compare: sorters.string("teamName"),
          },
          render: ({ team }) => <TeamName team={team} hideLogoOnMobile />,
          skeleton: <TeamNameSkeleton hideLogoOnMobile />,
        },
        {
          dataKey: "matches_played",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.games")}</span>
              <span className={styles.shortTitle}>{t("table.games_short")}</span>
            </>
          ),
          align: "right",
          className: styles.matchesPlayed,
        },
        {
          dataKey: "wins",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.wins")}</span>
              <span className={styles.shortTitle}>{t("table.wins_short")}</span>
            </>
          ),
          align: "right",
          className: styles.matchesWins,
          sorter: {
            compare: sorters.numbers("wins"),
            priority: 3,
          },
        },
        {
          dataKey: "draws",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.draws")}</span>
              <span className={styles.shortTitle}>{t("table.draws_short")}</span>
            </>
          ),
          align: "right",
          className: styles.matchesDraws,
          sorter: {
            compare: sorters.numbers("draws"),
          },
        },
        {
          dataKey: "loses",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.loses")}</span>
              <span className={styles.shortTitle}>{t("table.loses_short")}</span>
            </>
          ),
          align: "right",
          className: styles.matchesLoses,
          sorter: {
            compare: sorters.numbers("loses"),
          },
        },
        {
          dataKey: "scored_goals",
          title: t("table.gf"),
          align: "right",
          className: styles.goals,
          sorter: {
            compare: sorters.numbers("scored_goals"),
            priority: 2,
          },
        },
        {
          dataKey: "missed_goals",
          title: t("table.ga"),
          align: "right",
          className: styles.goals,
          sorter: {
            compare: sorters.numbers("missed_goals"),
          },
        },
        {
          dataKey: "goals_difference",
          title: t("table.gd"),
          align: "right",
          className: styles.goals,
          sorter: {
            compare: sorters.numbers("goals_difference"),
          },
        },
        {
          dataKey: "points",
          title: (
            <>
              <span className={styles.fullTitle}>{t("table.points")}</span>
              <span className={styles.shortTitle}>{t("table.points_short")}</span>
            </>
          ),
          align: "right",
          className: styles.points,
          dataClassName: styles.pointsData,
          sorter: {
            compare: sorters.numbers("points"),
            priority: 1,
          },
        },
        {
          dataKey: "total_score",
          title: t("table.ts"),
          align: "right",
          className: styles.totalScore,
          sorter: {
            compare: sorters.numbers("total_score", true),
            priority: 4,
          },
        },
        {
          dataKey: "form",
          title: t("table.form"),
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
            compare: sorters.numbers("formPoints"),
          },
        },
        {
          dataKey: "next",
          title: t("table.next"),
          className: styles.next,
          headEllipsis: styles.nextHead,
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
