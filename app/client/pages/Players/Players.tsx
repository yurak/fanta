import { useTranslation } from "react-i18next";
import Skeleton from "react-loading-skeleton";
import Heading from "@/components/Heading";
import PageLayout from "@/layouts/PageLayout";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersListContextProvider, {
  usePlayersListContext,
} from "@/application/Players/PlayersListContext";
import PlayersPageContextProvider, {
  usePlayersPageContext,
} from "@/application/Players/PlayersPageContext";
import Link from "@/ui/Link";
import PlayersFilters from "./PlayersFilters";
import PlayersList from "./PlayersList";
import PlayersFiltersDrawer from "./PlayersFilters/PlayersFiltersDrawer";
import UserCircleIcon from "@/assets/icons/userCircle.svg";
import styles from "./Players.module.scss";

const Players = () => {
  const { isLeagueSpecificPlayersPage, isLeagueFetching, league } = usePlayersPageContext();
  const { search, filterCount, setSearch, clearFilter, removeLeagueFilter } = usePlayersContext();
  const { totalItemCount } = usePlayersListContext();

  const { t } = useTranslation();

  const title = (
    <>
      {isLeagueSpecificPlayersPage ? (
        <>
          <span className={styles.desktop}>
            {isLeagueFetching || !league ? (
              <Skeleton containerClassName={styles.skeleton} />
            ) : (
              `${league.name} players`
            )}
          </span>
          <span className={styles.mobile}>{t("players.players")}</span>
        </>
      ) : (
        t("players.players")
      )}
    </>
  );

  const goToAllPlayers = () => {
    removeLeagueFilter();
  };

  return (
    <PageLayout>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.title}>
            <Heading title={title} noSpace />
          </div>
          {isLeagueSpecificPlayersPage && (
            <div className={styles.buttonWrapper}>
              <Link asButton onClick={goToAllPlayers} icon={<UserCircleIcon />}>
                <span className={styles.mobile}>All Players</span>
                <span className={styles.desktop}>All Mantra Players</span>
              </Link>
            </div>
          )}
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
    <PlayersPageContextProvider>
      <PlayersListContextProvider>
        <Players />
      </PlayersListContextProvider>
    </PlayersPageContextProvider>
  </PlayersContextProvider>
);
