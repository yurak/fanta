import { useMemo } from "react";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import { usePlayers } from "@/api/query/usePlayers";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import Link from "@/ui/Link";
import PlayersFilters from "./PlayersFilters";
import PlayersList from "./PlayersList";
import PlayersFiltersDrawer from "./PlayersFilters/PlayersFiltersDrawer";
import styles from "./Players.module.scss";

const Players = () => {
  const {
    search,
    sortBy,
    sortOrder,
    filterCount,
    clearAllFilter,
    onSortChange,
    setSearch,
    openSidebar,
    clearFilter,
    requestFilterPayload,
    requestSortPayload,
  } = usePlayersContext();

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isFetching, isPending } =
    usePlayers({
      filter: requestFilterPayload,
      sort: requestSortPayload,
    });

  const items = useMemo(() => data?.pages.flatMap((page) => page.data) ?? [], [data]);

  const totalItemCount = useMemo(() => {
    if (!data) {
      return 0;
    }

    const lastPage = data.pages.length - 1;

    return data.pages[lastPage]?.meta.size ?? 0;
  }, [data]);

  return (
    <PageLayout>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.heading}>
            <Heading title="Players" noSpace />
          </div>
        </div>
        <div className={styles.search}>
          <Search value={search} onChange={setSearch} placeholder="Search player" />
        </div>
      </div>
      <div className={styles.filtersWrapper}>
        <div className={styles.filters}>
          <PlayersFiltersDrawer />
          <PlayersFilters />
          {filterCount > 0 && (
            <Link asButton onClick={clearFilter}>
              Clear all
            </Link>
          )}
        </div>
        <div className={styles.total}>
          Showing
          <br />
          <span>
            {formatNumber(totalItemCount)} {totalItemCount === 1 ? "player" : "players"}
          </span>
        </div>
      </div>
      <div>
        <PlayersList
          fetchNextPage={fetchNextPage}
          hasNextPage={hasNextPage}
          isFetchingNextPage={isFetchingNextPage}
          isLoading={isPending || (isFetching && !isFetchingNextPage)}
          items={items}
          sorting={{
            onSortChange,
            sortBy,
            sortOrder,
          }}
          clearFilters={clearAllFilter}
          openFiltersSidebar={openSidebar}
        />
      </div>
    </PageLayout>
  );
};

export default () => (
  <PlayersContextProvider>
    <Players />
  </PlayersContextProvider>
);
