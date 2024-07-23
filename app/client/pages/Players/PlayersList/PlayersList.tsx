import { useCallback } from "react";
import { useMediaQuery } from "usehooks-ts";
import { IPlayer } from "@/interfaces/Player";
import PlayersListMobile from "./PlayersListMobile";
import PlayersListDesktop from "./PlayersListDesktop";
import { ISorting } from "@/hooks/useHistorySort";
import EmptyState from "@/ui/EmptyState";
import Button from "@/ui/Button";
import { useTranslation } from "react-i18next";

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
  const { t } = useTranslation();

  const loadMore = useCallback(() => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const isMobile = useMediaQuery("(max-width: 768px)");

  const emptyStateComponent = (
    <EmptyState
      title={t("players.results.playersNotFound")}
      description={t("players.results.playersNotFoundDescription")}
      actions={
        <>
          <Button onClick={openFiltersSidebar}>{t("players.filters.changeFilters")}</Button>
          <Button variant="secondary" onClick={clearFilters}>
            {t("players.filters.clearFilters")}
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
