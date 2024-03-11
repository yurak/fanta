import { useMediaQuery } from "usehooks-ts";
import { IPlayer } from "@/interfaces/Player";
import InfiniteScrollDetector from "@/components/InfiniteScrollDetector/InfiniteScrollDetector";
import { ITableSorting } from "@/ui/Table/interfaces";
import PlayersListMobile from "./PlayersListMobile";
import PlayersListDesktop from "./PlayersListDesktop";
import styles from "./PlayersList.module.scss";

const PlayersList = ({
  items,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
  isLoading,
  sorting,
}: {
  items: IPlayer[],
  fetchNextPage: () => void,
  hasNextPage: boolean,
  isFetchingNextPage: boolean,
  isLoading: boolean,
  sorting: ITableSorting,
}) => {
  const loadMore = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  const isMobile = useMediaQuery("(max-width: 768px)");

  return (
    <div>
      {isMobile ? (
        <PlayersListMobile items={items} isLoading={isLoading} sorting={sorting} />
      ) : (
        <PlayersListDesktop items={items} isLoading={isLoading} sorting={sorting} />
      )}
      {hasNextPage && (
        <InfiniteScrollDetector className={styles.loading} loadMore={loadMore}>
          Loading...
        </InfiniteScrollDetector>
      )}
    </div>
  );
};

export default PlayersList;
