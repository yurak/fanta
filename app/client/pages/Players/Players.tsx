import { useMemo } from "react";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import { usePlayers } from "@/api/query/usePlayers";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersFilters from "./PlayersFilters";
import PlayersList from "./PlayersList";
import styles from "./Players.module.scss";
import PlayersFiltersDrawer from "./PlayersFilters/PlayersFiltersDrawer";

const Players = () => {
  const {
    filter,
    clearAllFilter,
    search,
    sortBy,
    sortOrder,
    onSortChange,
    setSearch,
    openSidebar,
  } = usePlayersContext();

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isPending } = usePlayers({
    search,
    sortBy,
    sortOrder,
    filter,
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
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <PlayersFiltersDrawer />
          <PlayersFilters />
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
          isLoading={isPending}
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
