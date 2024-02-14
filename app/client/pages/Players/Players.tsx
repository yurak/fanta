import { useMemo, useState } from "react";
import Heading from "@/components/Heading";
import SeasonsSelect from "@/components/SeasonsSelect";
import PageLayout from "@/layouts/PageLayout";
import { ISeason } from "@/interfaces/Season";
import Search from "@/ui/Search";
import { usePlayers } from "@/api/query/usePlayers";
import PlayersFilters from "./PlayersFilters";
import styles from "./Players.module.scss";
import PlayersList from "./PlayersList";

const Players = () => {
  const [search, setSearch] = useState("");
  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = usePlayers({
    search,
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
      <div>
        <div>
          <PlayersFilters />
        </div>
        <div>
          Showing <b> {totalItemCount} players</b>
        </div>
      </div>
      <div>
        <PlayersList {...{ fetchNextPage, hasNextPage, isFetchingNextPage }} items={items} />
      </div>
    </PageLayout>
  );
};

export default Players;
