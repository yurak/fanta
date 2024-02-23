import { IPlayer } from "@/interfaces/Player";
import Table from "@/ui/Table";
import PlayersListInfo from "./PlayersListInfo";
import styles from "./PlayersList.module.scss";

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
