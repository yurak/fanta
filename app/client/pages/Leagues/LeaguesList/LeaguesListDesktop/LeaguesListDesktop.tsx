import { useMemo } from "react";
import Skeleton from "react-loading-skeleton";
import { useTranslation } from "react-i18next";
import Table, { IColumn } from "../../../../ui/Table";
import { ILeaguesWithTournament } from "../../interfaces";
import LeagueLoader from "../LeagueLoader";
import LeagueStatus from "../../../../components/LeagueStatus";
import styles from "./LeaguesListDesktop.module.scss";

const LeaguesListDesktop = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[];
  isLoading: boolean;
}) => {
  const { t } = useTranslation();

  const columns = useMemo<IColumn<ILeaguesWithTournament>[]>(
    () => [
      {
        title: t("league.name"),
        dataKey: "name",
        className: styles.leagueNameCell,
        render: (item) => (
          <span className={styles.leagueName}>
            {item.tournament && (
              <span className={styles.leagueImage}>
                <img src={item.tournament.logo} />
              </span>
            )}
            <span className={styles.leagueNameName}>{item.name}</span>
          </span>
        ),
        skeleton: (
          <span className={styles.leagueNameSkeleton}>
            <Skeleton containerClassName={styles.leagueNameSkeletonImage} />
            <Skeleton containerClassName={styles.leagueNameSkeletonName} />
          </span>
        ),
      },
      {
        title: t("league.division"),
        dataKey: "division",
        className: styles.divisionCell,
      },
      {
        title: t("league.season"),
        dataKey: "season",
        noWrap: true,
        className: styles.seasonCell,
        render: (item) => (
          <LeagueLoader leagueId={item.id}>
            {(league) => `${league.season_start_year}-${league.season_end_year}`}
          </LeagueLoader>
        ),
      },
      {
        title: t("league.tournament"),
        dataKey: "tournament",
        className: styles.tournamentCell,
        render: (item) => item.tournament?.name ?? "",
      },
      {
        title: t("league.leader"),
        dataKey: "leader",
        className: styles.leaderCell,
        render: (item) => (
          <LeagueLoader
            leagueId={item.id}
            skeleton={
              <span className={styles.leaderNameSkeleton}>
                <Skeleton containerClassName={styles.leaderNameSkeletonImage} />
                <Skeleton containerClassName={styles.leaderNameSkeletonName} />
              </span>
            }
          >
            {(league) => (
              <span className={styles.leaderName}>
                <span className={styles.leaderImage}>
                  <img src={league.leader_logo} />
                </span>
                <span className={styles.leaderNameName}>{league.leader}</span>
              </span>
            )}
          </LeagueLoader>
        ),
        skeleton: (
          <span className={styles.leaderNameSkeleton}>
            <Skeleton containerClassName={styles.leaderNameSkeletonImage} />
            <Skeleton containerClassName={styles.leaderNameSkeletonName} />
          </span>
        ),
      },
      {
        title: t("league.teams"),
        dataKey: "teams_count",
        align: "right",
        className: styles.teamsCell,
        render: (item) => (
          <LeagueLoader leagueId={item.id}>{(league) => league.teams_count}</LeagueLoader>
        ),
      },
      {
        title: t("league.round"),
        dataKey: "round",
        align: "right",
        className: styles.roundCell,
        render: (item) => (
          <LeagueLoader leagueId={item.id}>{(league) => league.round}</LeagueLoader>
        ),
      },
      {
        title: t("league.status"),
        dataKey: "status",
        align: "right",
        className: styles.statusCell,
        render: (item) => <LeagueStatus status={item.status} />,
      },
    ],
    [t]
  );

  return (
    <Table
      dataSource={dataSource}
      columns={columns}
      rowLink={(item) => item.link}
      isLoading={isLoading}
      skeletonItems={10}
      emptyState={{ title: t("league.empty_placeholder") }}
    />
  );
};

export default LeaguesListDesktop;
