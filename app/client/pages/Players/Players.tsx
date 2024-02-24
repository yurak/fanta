import { useMemo, useState } from "react";
import Heading from "@/components/Heading";
import SeasonsSelect from "@/components/SeasonsSelect";
import PageLayout from "@/layouts/PageLayout";
import { ISeason } from "@/interfaces/Season";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import { usePlayers } from "@/api/query/usePlayers";
import PlayersFilters from "./PlayersFilters";
import PlayersList from "./PlayersList";
import styles from "./Players.module.scss";

const Players = () => {
  const [search, setSearch] = useState("");
  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isPending, ...rest } = usePlayers({
    search,
  });

  console.log({
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isPending,
    ...rest,
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
        <div className={styles.heading}>
          <Heading title="Players" noSpace />
        </div>
        <div className={styles.yearSelect}>
          <SeasonsSelect value={selectedSeason} onChange={setSelectedSeason} />
        </div>
        <div className={styles.search}>
          <Search value={search} onChange={setSearch} placeholder="Search player" />
        </div>
      </div>
      <div className={styles.filtersWrapper}>
        <div>
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
        />
      </div>
    </PageLayout>
  );
};

export default Players;
