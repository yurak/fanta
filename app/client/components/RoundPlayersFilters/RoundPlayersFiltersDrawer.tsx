import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useMediaQuery } from "usehooks-ts";
import RoundPlayersFilterContextProvider, {
  useRoundPlayersFilterContext,
} from "@/application/RoundPlayers/RoundPlayersFilterContext";
import RoundPlayersSortContextProvider, {
  useRoundPlayersSortContext,
} from "@/application/RoundPlayers/RoundPlayersSortContext";
import { useRoundPlayersContext } from "@/application/RoundPlayers/RoundPlayersContext";
import { useRoundPlayersPageConfigurationContext } from "@/application/RoundPlayers/RoundPlayersPageConfigurationContext";
import Drawer from "@/ui/Drawer";
import Link from "@/ui/Link";
import Button from "@/ui/Button";
import FilterIcon from "@/assets/icons/filter.svg";
import PlayerPositionsCheckbox from "@/components/filters/PlayerPositionsCheckbox";
import { LeagueRadioGroup } from "./LeagueFilter";
import { RoundClubCheckboxList } from "./RoundClubCheckbox/RoundClubCheckbox";
import RoundPlayersSortDrawer from "./RoundPlayersSortDrawer";
import styles from "./RoundPlayersFiltersDrawer.module.scss";

const RoundPlayersFiltersDrawer = () => {
  const isMobile = useMediaQuery("(max-width: 768px)");

  const { filterCount, clearFilter } = useRoundPlayersContext();
  const { filterValues, onChangeValue, applyFilter } = useRoundPlayersFilterContext();
  const { selectedSort } = useRoundPlayersSortContext();
  const { leagues, clubs, national } = useRoundPlayersPageConfigurationContext();

  const { t } = useTranslation();

  const [isOpen, setIsOpen] = useState(false);
  const [isSortOpen, setIsSortOpen] = useState(false);

  const applyHandler = () => {
    applyFilter();
    setIsOpen(false);
  };

  const clearHandler = () => {
    clearFilter();
    setIsOpen(false);
  };

  return (
    <div className={styles.trigger}>
      <Link asButton icon={<FilterIcon />} onClick={() => setIsOpen(true)}>
        {t("round_players_page.all_filters")} {filterCount > 0 ? `(${filterCount})` : ""}
      </Link>
      <Drawer
        title={t("round_players_page.all_filters")}
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        noPadding
        footer={
          <div className={styles.footer}>
            <Link asButton onClick={clearHandler}>
              {t("round_players_page.clear_all")}
            </Link>
            <Button onClick={applyHandler}>{t("round_players_page.apply")}</Button>
          </div>
        }
      >
        {isMobile && (
          <Drawer.Button
            title={t("round_players_page.sorter.sort_by")}
            onClick={() => setIsSortOpen(true)}
            value={selectedSort && <span className={styles.sortLabel}>{selectedSort.label}</span>}
          />
        )}
        {leagues.length > 0 && (
          <Drawer.Section
            title={t("round_players_page.filters.league")}
            withTopSpace
            defaultOpen={!!filterValues.leagueId}
          >
            <LeagueRadioGroup
              leagues={leagues}
              value={filterValues.leagueId}
              onChange={onChangeValue("leagueId")}
            />
          </Drawer.Section>
        )}
        <Drawer.Section
          title={t("round_players_page.filters.position")}
          withTopSpace
          withBottomSpace={clubs.length === 0}
          defaultOpen={filterValues.position.length > 0}
        >
          <PlayerPositionsCheckbox
            value={filterValues.position}
            onChange={onChangeValue("position")}
          />
        </Drawer.Section>
        {clubs.length > 0 && (
          <Drawer.Section
            title={national ? t("round_players_page.filters.teams") : t("round_players_page.filters.clubs")}
            withTopSpace
            withBottomSpace
            defaultOpen={filterValues.clubs.length > 0}
          >
            <RoundClubCheckboxList
              clubs={clubs}
              value={filterValues.clubs}
              onChange={onChangeValue("clubs")}
            />
          </Drawer.Section>
        )}
      </Drawer>
      {isMobile && (
        <RoundPlayersSortDrawer isOpen={isSortOpen} close={() => setIsSortOpen(false)} />
      )}
    </div>
  );
};

export default () => (
  <RoundPlayersSortContextProvider>
    <RoundPlayersFilterContextProvider>
      <RoundPlayersFiltersDrawer />
    </RoundPlayersFilterContextProvider>
  </RoundPlayersSortContextProvider>
);
