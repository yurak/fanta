import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Table, { IColumn } from "../../../ui/Table";
import { ILeaguesWithTournament } from "../interfaces";
import LeagueLoader from "./LeagueLoader";
import LeagueStatus from "../../../components/LeagueStatus";
import styles from "./LeaguesTable.module.scss";

const LeaguesTable = ({
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
        dataKey: "tournamentLogo",
        render: (item) => {
          if (!item.tournament) {
            return null;
          }

          return <img src={item.tournament.logo} width="32" height="32" />;
        },
        headColSpan: 0,
        width: 30,
      },
      {
        title: t("league.name"),
        dataKey: "name",
        headColSpan: 2,
        className: styles.leagueName,
      },
      {
        title: t("league.division"),
        dataKey: "division",
      },
      {
        title: t("league.season"),
        dataKey: "season",
        width: 112,
        noWrap: true,
        render: (item) => (
          <LeagueLoader leagueId={item.id}>
            {(league) => `${league.season_start_year}-${league.season_end_year}`}
          </LeagueLoader>
        ),
      },
      {
        title: t("league.tournament"),
        dataKey: "tournament",
        render: (item) => item.tournament?.name ?? "",
      },
      {
        title: t("league.leader"),
        dataKey: "leader",
        render: (item) => (
          <LeagueLoader leagueId={item.id}>{(league) => <>{league.leader}</>}</LeagueLoader>
        ),
      },
      {
        title: t("league.teams"),
        dataKey: "teams_count",
        align: "right",
        width: 112,
        render: (item) => (
          <LeagueLoader leagueId={item.id}>{(league) => league.teams_count}</LeagueLoader>
        ),
      },
      {
        title: t("league.round"),
        dataKey: "round",
        width: 112,
        align: "right",
        render: (item) => (
          <LeagueLoader leagueId={item.id}>{(league) => league.round}</LeagueLoader>
        ),
      },
      {
        title: t("league.status"),
        dataKey: "status",
        align: "right",
        width: 112,
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
    />
  );
};

export default LeaguesTable;
