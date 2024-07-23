import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { IPlayer } from "@/interfaces/Player";
import Table, { IColumn } from "@/ui/Table";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";
import { ISorting } from "@/hooks/useHistorySort";
import PlayersListInfo, { PlayersListInfoSkeleton } from "../PlayersListInfo";
import styles from "./PlayersListDesktop.module.scss";

const PlayersListDesktop = ({
  items,
  isLoading,
  isLoadingMore,
  onLoadMore,
  sorting,
  emptyStateComponent,
}: {
  items: IPlayer[],
  isLoading: boolean,
  isLoadingMore: boolean,
  onLoadMore: () => void,
  sorting: Partial<ISorting>,
  emptyStateComponent: React.ReactNode,
}) => {
  const { t } = useTranslation();

  const columns = useMemo<IColumn<IPlayer>[]>(
    () => [
      {
        dataKey: "name",
        title: t("players.filters.nameLabel"),
        dataClassName: styles.nameDataCell,
        className: styles.nameCell,
        sorter: true,
        supportAscSorting: true,
        render: (player) => <PlayersListInfo player={player} />,
        skeleton: <PlayersListInfoSkeleton />,
      },
      {
        dataKey: "tournament",
        title: t("players.filters.tournamentLabel"),
        className: styles.tournamentCell,
        headEllipsis: true,
        render: ({ club }) => {
          if (!club.tournament_id) {
            return "-";
          }

          return (
            <TournamentsLoader>
              {(tournaments) => {
                const tournament = tournaments.find((t) => t.id === club.tournament_id);

                if (!tournament) {
                  return "-";
                }

                return (
                  <div className={styles.logo}>
                    <img src={tournament.logo} alt={tournament.name} />
                  </div>
                );
              }}
            </TournamentsLoader>
          );
        },
      },
      {
        dataKey: "club",
        title: t("players.filters.clubLabel"),
        className: styles.clubCell,
        render: ({ club }) => {
          return (
            <div className={styles.logo}>
              <img src={club.logo_path} alt={club.name} />
            </div>
          );
        },
      },
      {
        dataKey: "position",
        title: t("players.filters.positionLabel"),
        className: styles.positionsCell,
        sorter: true,
        supportAscSorting: true,
        render: ({ position_classic_arr }) => <PlayerPositions position={position_classic_arr} />,
      },
      {
        dataKey: "average_price",
        title: "Price",
        align: "right",
        className: styles.priceCell,
        noWrap: true,
        sorter: true,
        supportAscSorting: true,
        render: ({ average_price }) => {
          return formatNumber(average_price, {
            zeroFallback: "-",
            minimumFractionDigits: 1,
            maximumFractionDigits: 1,
            suffix: "M",
          });
        },
      },
      {
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
          if (teams_count === 0) {
            return 0;
          }

          return (
            <>
              {formatNumber(teams_count)}{" "}
              <span className={styles.totalTeamCount}>({formatNumber(teams_count_max)})</span>
            </>
          );
        },
      },
      {
        dataKey: "appearances",
        title: t("players.filters.appearancesShortLabel"),
        align: "right",
        noWrap: true,
        headEllipsis: true,
        className: styles.appsCell,
        sorter: true,
        supportAscSorting: true,
        render: ({ appearances, appearances_max }) => {
          if (appearances === 0) {
            return 0;
          }

          return (
            <>
              {formatNumber(appearances)}{" "}
              <span className={styles.totalApps}>({formatNumber(appearances_max)})</span>
            </>
          );
        },
      },
      {
        dataKey: "base_score",
        align: "right",
        title: t("players.filters.baseScoreShortLabel"),
        className: styles.baseScoreCell,
        sorter: true,
        supportAscSorting: true,
        noWrap: true,
        render: ({ average_base_score }) => {
          return formatNumber(Number(average_base_score), {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          });
        },
      },
      {
        dataKey: "total_score",
        title: t("players.filters.totalScoreShortLabel"),
        align: "right",
        dataClassName: styles.totalScoreDataCell,
        className: styles.totalScoreCell,
        sorter: true,
        supportAscSorting: true,
        noWrap: true,
        render: ({ average_total_score }) => {
          return formatNumber(Number(average_total_score), {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          });
        },
      },
    ],
    [t]
  );

  return (
    <Table
      rounded
      dataSource={items}
      isLoading={isLoading}
      isLoadingMore={isLoadingMore}
      onLoadMore={onLoadMore}
      sorting={sorting}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={25}
      rowLink={(item) => `/players/${item.id}`}
      columns={columns}
    />
  );
};

export default PlayersListDesktop;
