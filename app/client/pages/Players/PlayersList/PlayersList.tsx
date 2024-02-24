import { IPlayer } from "@/interfaces/Player";
import Table from "@/ui/Table";
import PlayersListInfo from "./PlayersListInfo";
import styles from "./PlayersList.module.scss";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";

const PlayersList = ({
  items,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
}: {
  items: IPlayer[],
  fetchNextPage: () => void,
  hasNextPage: boolean,
  isFetchingNextPage: boolean,
}) => {
  return (
    <div>
      <Table
        rounded
        dataSource={items}
        columns={[
          {
            dataKey: "name",
            title: "Name",
            dataClassName: styles.nameDataCell,
            render: (player) => <PlayersListInfo player={player} />,
          },
          {
            dataKey: "tournament",
            title: "TMNT",
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
            dataKey: "average_price",
            title: "Price",
            render: ({ average_price }) => (average_price ? `${average_price}M` : "-"),
          },
          {
            dataKey: "teams_count",
            title: "# of teams",
          },
          {
            dataKey: "appearances",
            title: "Apps",
          },
          {
            dataKey: "average_base_score",
            title: "BS",
          },
          {
            dataKey: "average_total_score",
            title: "TS",
          },
          {
            dataKey: "club",
            title: "Club",
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
      <div>
        <button onClick={() => fetchNextPage()} disabled={!hasNextPage || isFetchingNextPage}>
          {isFetchingNextPage
            ? "Loading more..."
            : hasNextPage
            ? "Load More"
            : "Nothing more to load"}
        </button>
      </div>
    </div>
  );
};

export default PlayersList;
