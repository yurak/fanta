import { IPlayer } from "@/interfaces/Player";
import Table from "@/ui/Table";
import PlayersListInfo from "./PlayersListInfo";
import styles from "./PlayersList.module.scss";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import InfiniteScrollDetector from "@/components/InfiniteScrollDetector/InfiniteScrollDetector";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";

const PlayersList = ({
  items,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
  isLoading,
  setSortField,
  sortField,
}: {
  items: IPlayer[],
  fetchNextPage: () => void,
  hasNextPage: boolean,
  isFetchingNextPage: boolean,
  isLoading: boolean,
  setSortField: (sortField: null | string) => void,
  sortField: null | string,
}) => {
  const loadMore = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  return (
    <div>
      <Table
        rounded
        dataSource={items}
        isLoading={isLoading}
        sorting={{
          setSortColumn: setSortField,
          sortColumn: sortField,
        }}
        columns={[
          {
            dataKey: "name",
            title: "Name",
            dataClassName: styles.nameDataCell,
            className: styles.nameCell,
            sorter: true,
            render: (player) => <PlayersListInfo player={player} />,
          },
          {
            dataKey: "tournament",
            title: "TMNT",
            className: styles.tournamentCell,
            sorter: true,
            render: ({ club }) => {
              if (!club.tournament_id) {
                return null;
              }

              return (
                <TournamentsLoader>
                  {(tournaments) => {
                    const tournament = tournaments.find((t) => t.id === club.tournament_id);

                    if (!tournament) {
                      return null;
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
            dataKey: "position",
            title: "Position",
            className: styles.positionsCell,
            sorter: true,
            render: ({ position_classic_arr }) => (
              <PlayerPositions positions={position_classic_arr} />
            ),
          },
          {
            dataKey: "average_price",
            title: "Price",
            align: "right",
            className: styles.priceCell,
            sorter: true,
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
            title: "# of teams",
            align: "right",
            className: styles.totalTeamsCell,
            sorter: true,
            render: ({ teams_count }) => {
              if (teams_count === 0) {
                return 0;
              }

              return (
                <>
                  {formatNumber(teams_count)} <span className={styles.totalTeamCount}>(n/a)</span>
                </>
              );
            },
          },
          {
            dataKey: "appearances",
            title: "Apps",
            align: "right",
            className: styles.appsCell,
            sorter: true,
            render: ({ appearances }) => {
              if (appearances === 0) {
                return 0;
              }

              return (
                <>
                  {formatNumber(appearances)} <span className={styles.totalApps}>(n/a)</span>
                </>
              );
            },
          },
          {
            dataKey: "average_base_score",
            align: "right",
            title: "BS",
            className: styles.baseScoreCell,
            sorter: true,
            render: ({ average_base_score }) => {
              return formatNumber(Number(average_base_score), {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              });
            },
          },
          {
            dataKey: "average_total_score",
            title: "TS",
            align: "right",
            dataClassName: styles.totalScoreDataCell,
            className: styles.totalScoreCell,
            sorter: true,
            render: ({ average_total_score }) => {
              return formatNumber(Number(average_total_score), {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              });
            },
          },
          {
            dataKey: "club",
            title: "Club",
            className: styles.clubCell,
            sorter: true,
            render: ({ club }) => {
              return (
                <div className={styles.logo}>
                  <img src={club.logo_path} alt={club.name} />
                </div>
              );
            },
          },
        ]}
      />
      {hasNextPage && (
        <InfiniteScrollDetector className={styles.loading} loadMore={loadMore}>
          Loading...
        </InfiniteScrollDetector>
      )}
    </div>
  );
};

export default PlayersList;
