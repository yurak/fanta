import { useMediaQuery } from "usehooks-ts";
import { IPlayer } from "@/interfaces/Player";
import PlayersListMobile from "./PlayersListMobile";
import PlayersListDesktop from "./PlayersListDesktop";
import { ISorting } from "@/hooks/useHistorySort";
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
  sorting: Partial<ISorting>,
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
          isLoadingMore={hasNextPage}
          onLoadMore={loadMore}
          emptyStateComponent={emptyStateComponent}
        />
      ) : (
        <PlayersListDesktop
          items={items}
          isLoading={isLoading}
          isLoadingMore={hasNextPage}
          onLoadMore={loadMore}
          sorting={sorting}
          emptyStateComponent={emptyStateComponent}
        />
      )}
    </div>
  );
};

export default PlayersList;
