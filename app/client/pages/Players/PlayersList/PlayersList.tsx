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
}: {
  items: IPlayer[],
  fetchNextPage: () => void,
  hasNextPage: boolean,
  isFetchingNextPage: boolean,
  isLoading: boolean,
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
        columns={[
          {
            dataKey: "name",
            title: "Name",
            dataClassName: styles.nameDataCell,
            className: styles.nameCell,
            render: (player) => <PlayersListInfo player={player} />,
          },
          {
            dataKey: "tournament",
            title: "TMNT",
            className: styles.tournamentCell,
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
            render: ({ position_classic_arr }) => (
              <PlayerPositions positions={position_classic_arr} />
            ),
          },
          {
            dataKey: "average_price",
            title: "Price",
            align: "right",
            className: styles.priceCell,
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
