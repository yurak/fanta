import { useMediaQuery } from "usehooks-ts";
import { IPlayer } from "@/interfaces/Player";
import InfiniteScrollDetector from "@/components/InfiniteScrollDetector/InfiniteScrollDetector";
import { ITableSorting } from "@/ui/Table/interfaces";
import PlayersListMobile from "./PlayersListMobile";
import PlayersListDesktop from "./PlayersListDesktop";
import styles from "./PlayersList.module.scss";
import EmptyState from "@/ui/EmptyState";
import Button from "@/ui/Button";

const PlayersList = ({
  items,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
  isLoading,
  sorting,
  openFiltersSidebar,
  clearFilters,
}: {
  items: IPlayer[],
  fetchNextPage: () => void,
  hasNextPage: boolean,
  isFetchingNextPage: boolean,
  isLoading: boolean,
  sorting: ITableSorting,
  openFiltersSidebar: () => void,
  clearFilters: () => void,
}) => {
  const loadMore = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  const isMobile = useMediaQuery("(max-width: 768px)");

  const emptyStateComponent = (
    <EmptyState
      title="Players not found"
      description="Make sure that the player’s name is spelled correctly or try other filter parameters"
      actions={
        <>
          <Button onClick={openFiltersSidebar}>Change filters</Button>
          <Button variant="secondary" onClick={clearFilters}>
            Clear filters
          </Button>
        </>
      }
    />
  );

  return (
    <div>
      {isMobile ? (
        <PlayersListMobile
          items={items}
          isLoading={isLoading}
          emptyStateComponent={emptyStateComponent}
        />
      ) : (
        <PlayersListDesktop
          items={items}
          isLoading={isLoading}
          sorting={sorting}
          emptyStateComponent={emptyStateComponent}
        />
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
