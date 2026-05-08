import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { IPlayer } from "@/interfaces/Player";
import Table, { IColumn } from "@/ui/Table";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";
import { usePlayersContext } from "@/application/Players/PlayersContext";
import { usePlayersPageConfigurationContext } from "@/application/Players/PlayersPageConfigurationContext";
import { usePlayersListContext } from "@/application/Players/PlayersListContext";
import PlayersListInfo, { PlayersListInfoSkeleton } from "../PlayersListInfo";
import styles from "./PlayersListDesktop.module.scss";

const PlayersListDesktop = ({ emptyStateComponent }: { emptyStateComponent: React.ReactNode }) => {
  const { t } = useTranslation();
  const { sorting } = usePlayersContext();
  const { items, isLoading, hasNextPage, loadMore } = usePlayersListContext();
  const { isLeagueSpecificPlayersPage } = usePlayersPageConfigurationContext();

  const columns = useMemo<IColumn<IPlayer>[]>(() => {
    const nameCol: IColumn<IPlayer> = {
      dataKey: "name",
      title: t("players.filters.nameLabel"),
      dataClassName: styles.nameDataCell,
      className: styles.nameCell,
      sorter: true,
      supportAscSorting: true,
      render: (player) => <PlayersListInfo player={player} />,
      skeleton: <PlayersListInfoSkeleton />,
    };

    const tournamentCol: IColumn<IPlayer> = {
      dataKey: "tournament",
      title: t("players.filters.tournamentLabel"),
      className: styles.tournamentCell,
      headEllipsis: true,
      render: ({ club }) => {
        if (!club.tournament_id) return "-";

        return (
          <TournamentsLoader>
            {(tournaments) => {
              const tournament = tournaments.find((t) => t.id === club.tournament_id);
              if (!tournament) return "-";

              return (
                <div className={styles.logo}>
                  <img src={tournament.logo} alt={tournament.name} />
                </div>
              );
            }}
          </TournamentsLoader>
        );
      },
    };

    const clubCol: IColumn<IPlayer> = {
      dataKey: "club",
      title: t("players.filters.clubLabel"),
      className: styles.clubCell,
      render: ({ club }) => (
        <div className={styles.logo}>
          <img src={club.logo_path} alt={club.name} />
        </div>
      ),
    };

    const positionCol: IColumn<IPlayer> = {
      dataKey: "position",
      title: t("players.filters.positionLabel"),
      className: styles.positionsCell,
      sorter: true,
      supportAscSorting: true,
      render: ({ position_classic_arr }) => <PlayerPositions position={position_classic_arr} />,
    };

    const avgPriceCol: IColumn<IPlayer> = {
      dataKey: "average_price",
      title: t("players.filters.priceLabel"),
      align: "right",
      className: styles.priceCell,
      noWrap: true,
      headEllipsis: true,
      render: ({ average_price }) =>
        formatNumber(average_price, {
          zeroFallback: "-",
          minimumFractionDigits: 1,
          maximumFractionDigits: 1,
          suffix: "M",
        }),
    };

    const leaguePriceCol: IColumn<IPlayer> = {
      dataKey: "league_price",
      title: t("players.filters.priceLabel"),
      align: "right",
      className: styles.priceCell,
      noWrap: true,
      sorter: true,
      headEllipsis: true,
      supportAscSorting: true,
      render: ({ league_price }) =>
        formatNumber(league_price ?? 0, {
          zeroFallback: "-",
          minimumFractionDigits: 1,
          maximumFractionDigits: 1,
          suffix: "M",
        }),
    };

    const teamsCountCol: IColumn<IPlayer> = {
      dataKey: "teams_count",
      title: (
        <>
          <span className={styles.desktopTitle}>{t("players.filters.numberOfTeamsLabel")}</span>
          <span className={styles.mobileTitle}>
            {t("players.filters.numberOfTeamsShortLabel")}
          </span>
        </>
      ),
      headEllipsis: true,
      align: "right",
      noWrap: true,
      className: styles.totalTeamsCell,
      render: ({ teams_count, teams_count_max }) => {
        if (teams_count === 0) return 0;

        return (
          <>
            {formatNumber(teams_count)}{" "}
            <span className={styles.totalTeamCount}>({formatNumber(teams_count_max)})</span>
          </>
        );
      },
    };

    const appsCol: IColumn<IPlayer> = {
      dataKey: "appearances",
      title: t("players.filters.appearancesShortLabel"),
      align: "right",
      noWrap: true,
      headEllipsis: true,
      className: styles.appsCell,
      sorter: true,
      supportAscSorting: true,
      render: ({ appearances, appearances_max }) => {
        if (appearances === 0) return 0;

        return (
          <>
            {formatNumber(appearances)}{" "}
            <span className={styles.totalApps}>({formatNumber(appearances_max)})</span>
          </>
        );
      },
    };

    const baseScoreCol: IColumn<IPlayer> = {
      dataKey: "base_score",
      align: "right",
      title: t("players.filters.baseScoreShortLabel"),
      className: styles.baseScoreCell,
      sorter: true,
      supportAscSorting: true,
      noWrap: true,
      render: ({ average_base_score }) =>
        formatNumber(Number(average_base_score), {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        }),
    };

    const totalScoreCol: IColumn<IPlayer> = {
      dataKey: "total_score",
      title: t("players.filters.totalScoreShortLabel"),
      align: "right",
      dataClassName: styles.totalScoreDataCell,
      className: styles.totalScoreCell,
      sorter: true,
      supportAscSorting: true,
      noWrap: true,
      render: ({ average_total_score }) =>
        formatNumber(Number(average_total_score), {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        }),
    };

    const teamCol: IColumn<IPlayer> = {
      dataKey: "team",
      title: t("players.filters.teamLabel"),
      className: styles.clubCell,
      render: ({ league_team_logo }) => {
        if (!league_team_logo) return "-";

        return (
          <div className={styles.logo}>
            <img src={league_team_logo} alt="League team" />
          </div>
        );
      },
    };

    if (isLeagueSpecificPlayersPage) {
      return [nameCol, positionCol, teamCol, leaguePriceCol, appsCol, baseScoreCol, totalScoreCol, clubCol];
    }

    return [nameCol, tournamentCol, clubCol, positionCol, avgPriceCol, teamsCountCol, appsCol, baseScoreCol, totalScoreCol];
  }, [t, isLeagueSpecificPlayersPage]);

  return (
    <Table
      rounded
      dataSource={items}
      isLoading={isLoading}
      isLoadingMore={hasNextPage}
      onLoadMore={loadMore}
      sorting={sorting}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={25}
      rowLink={(item) => `/players/${item.id}`}
      columns={columns}
    />
  );
};

export default PlayersListDesktop;
