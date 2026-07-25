import cn from "classnames";
import qs from "qs";
import { useTranslation } from "react-i18next";
import Heading from "@/components/Heading";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import PlayersContextProvider, { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersListContextProvider, {
  usePlayersListContext,
} from "@/application/Players/PlayersListContext";
import { usePlayersPageConfigurationContext } from "@/application/Players/PlayersPageConfigurationContext";
import Link from "@/ui/Link";
import Button from "@/ui/Button";
import SeasonsSelect from "@/components/SeasonsSelect";
import PlayersFilters from "../PlayersFilters";
import PlayersList from "../PlayersList";
import PlayersFiltersDrawer from "../PlayersFilters/PlayersFiltersDrawer";
import styles from "./PlayersPage.module.scss";

interface IProps {
  title: React.ReactNode,
  actions?: React.ReactNode,
}

const PlayersPage = ({ title, actions }: IProps) => {
  const { search, filterCount, setSearch, clearFilter, selectedSeason, setSelectedSeason, requestFilterPayload } =
    usePlayersContext();
  const { totalItemCount } = usePlayersListContext();
  const { isLeagueSpecificPlayersPage } = usePlayersPageConfigurationContext();

  const { t } = useTranslation();

  const handleExport = () => {
    const query = qs.stringify(
      { filter: requestFilterPayload },
      { arrayFormat: "brackets", encodeValuesOnly: true }
    );
    window.location.href = `/api/players/stats_export?${query}`;
  };

  return (
    <>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div
            className={cn(styles.title, {
              [styles.titleHiddenMobile]: !isLeagueSpecificPlayersPage,
            })}
          >
            <Heading title={title} noSpace />
          </div>
          {!isLeagueSpecificPlayersPage && (
            <div className={styles.seasonControls}>
              <SeasonsSelect value={selectedSeason} onChange={setSelectedSeason} />
              <Button onClick={handleExport}>{t("players.export_csv")}</Button>
            </div>
          )}
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
