import { useTranslation } from "react-i18next";
import Heading from "@/components/Heading";
import { formatNumber } from "@/helpers/formatNumber";
import Search from "@/ui/Search";
import Link from "@/ui/Link";
import RoundPlayersContextProvider, {
  useRoundPlayersContext,
} from "@/application/RoundPlayers/RoundPlayersContext";
import RoundPlayersListContextProvider, {
  useRoundPlayersListContext,
} from "@/application/RoundPlayers/RoundPlayersListContext";
import RoundPlayersFilters from "../RoundPlayersFilters";
import RoundPlayersFiltersDrawer from "../RoundPlayersFilters/RoundPlayersFiltersDrawer";
import RoundPlayersList from "../RoundPlayersList";
import styles from "./RoundPlayersPage.module.scss";

interface IProps {
  title: React.ReactNode,
}

const RoundPlayersPage = ({ title }: IProps) => {
  const { search, filterCount, setSearch, clearFilter } = useRoundPlayersContext();
  const { totalItemCount } = useRoundPlayersListContext();

  const { t } = useTranslation();

  return (
    <>
      <div className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.title}>
            <Heading title={title} noSpace />
          </div>
        </div>
        <div className={styles.search}>
          <Search
            value={search}
            onChange={setSearch}
            placeholder={t("round_players_page.search_player")}
            autofocus
          />
        </div>
      </div>
      <div className={styles.filtersWrapper}>
        <div className={styles.filters}>
          <RoundPlayersFilters />
          <RoundPlayersFiltersDrawer />
          {filterCount > 0 && (
            <Link asButton onClick={clearFilter}>
              {t("round_players_page.clear_filters")}
            </Link>
          )}
        </div>
        <div className={styles.total}>
          {t("round_players_page.results_title")}
          <br />
          <span>
            {formatNumber(totalItemCount)} {t("round_players_page.player", { count: totalItemCount })}
          </span>
        </div>
      </div>
      <RoundPlayersList />
    </>
  );
};

export default (props: IProps) => (
  <RoundPlayersContextProvider>
    <RoundPlayersListContextProvider>
      <RoundPlayersPage {...props} />
    </RoundPlayersListContextProvider>
  </RoundPlayersContextProvider>
);
