import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Table, { IColumn } from "../../../ui/Table";
import { ILeaguesWithTournament } from "../interfaces";
import styles from "./LeaguesTable.module.scss";

const LeaguesTable = ({
  dataSource: originDataSource,
  search,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[];
  search: string;
  isLoading: boolean;
}) => {
  const { t } = useTranslation();

  const dataSource = useMemo(() => {
    if (!search) {
      return originDataSource;
    }

    const searchInLowerCase = search.toLowerCase();

    return originDataSource.filter((league) =>
      league.name.toLowerCase().includes(searchInLowerCase)
    );
  }, [originDataSource, search]);

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
        title: t("league.season"),
        dataKey: "season",
        width: 112,
        // render: (item) => `${item.season_start_year} - ${item.season_end_year}`,
        noWrap: true,
      },
      {
        title: t("league.tournament"),
        dataKey: "tournament",
        render: (item) => item.tournament?.name ?? "",
      },
      {
        title: t("league.teams"),
        dataKey: "teams_count",
        align: "right",
        width: 112,
      },
      {
        title: t("league.leader"),
        dataKey: "leader",
      },
      {
        title: t("league.round"),
        dataKey: "round",
        width: 112,
      },
      {
        title: t("league.status"),
        dataKey: "status",
        width: 112,
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
    />
  );
};

export default LeaguesTable;
