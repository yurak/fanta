import PlayerAvatar from "@/components/PlayerAvatar";
import { IPlayer } from "@/interfaces/Player";
import Table from "@/ui/Table";

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
        dataSource={items}
        columns={[
          {
            dataKey: "name",
            title: "Name",
            render: ({ first_name, name, avatar_path, club }) => (
              <div>
                <div>
                  <PlayerAvatar avatarSrc={avatar_path} clubKitSrc={club.kit_path} />
                </div>
                <div>
                  <div>{first_name}</div>
                  <div>{name}</div>
                </div>
              </div>
            ),
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
