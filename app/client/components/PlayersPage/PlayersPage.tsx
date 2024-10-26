import { useTranslation } from "react-i18next";
import Heading from "@/components/Heading";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersListContextProvider, {
  usePlayersListContext,
} from "@/application/Players/PlayersListContext";
import Link from "@/ui/Link";
import PlayersFilters from "../PlayersFilters";
import PlayersList from "../PlayersList";
import PlayersFiltersDrawer from "../PlayersFilters/PlayersFiltersDrawer";
import styles from "./PlayersPage.module.scss";

interface IProps {
  title: React.ReactNode,
  actions?: React.ReactNode,
}

const PlayersPage = ({ title, actions }: IProps) => {
  const { search, filterCount, setSearch, clearFilter } = usePlayersContext();
  const { totalItemCount } = usePlayersListContext();

  const { t } = useTranslation();

  return (
    <>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.title}>
            <Heading title={title} noSpace />
          </div>
          {actions && <div className={styles.buttonWrapper}>{actions}</div>}
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
    </>
  );
};

export default (props: IProps) => (
  <PlayersContextProvider>
    <PlayersListContextProvider>
      <PlayersPage {...props} />
    </PlayersListContextProvider>
  </PlayersContextProvider>
);
