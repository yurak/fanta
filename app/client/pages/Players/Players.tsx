import { useTranslation } from "react-i18next";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersListContextProvider, {
  usePlayersListContext,
} from "@/application/Players/PlayersListContext";
import Link from "@/ui/Link";
import PlayersFilters from "./PlayersFilters";
import PlayersList from "./PlayersList";
import PlayersFiltersDrawer from "./PlayersFilters/PlayersFiltersDrawer";
import styles from "./Players.module.scss";

const Players = () => {
  const { search, filterCount, setSearch, clearFilter } = usePlayersContext();
  const { totalItemCount } = usePlayersListContext();

  const { t } = useTranslation();

  return (
    <PageLayout>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.heading}>
            <Heading title={t("players.players")} noSpace />
          </div>
        </div>
        <div className={styles.search}>
          <Search
            value={search}
            onChange={setSearch}
            placeholder={t("players.search_player")}
            autofocus
          />
        </div>
      </div>
      <div className={styles.filtersWrapper}>
        <div className={styles.filters}>
          <PlayersFiltersDrawer />
          <PlayersFilters />
          {filterCount > 0 && (
            <Link asButton onClick={clearFilter}>
              {t("players.filters.clearFilters")}
            </Link>
          )}
        </div>
        <div className={styles.total}>
          {t("players.results.title")}
          <br />
          <span>
            {formatNumber(totalItemCount)} {t("players.results.player", { count: totalItemCount })}
          </span>
        </div>
      </div>
      <PlayersList />
    </PageLayout>
  );
};

export default () => (
  <PlayersContextProvider>
    <PlayersListContextProvider>
      <Players />
    </PlayersListContextProvider>
  </PlayersContextProvider>
);
