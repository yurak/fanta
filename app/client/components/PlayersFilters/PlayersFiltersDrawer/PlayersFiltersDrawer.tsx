import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useMediaQuery } from "usehooks-ts";
import PlayersFilterContextProvider, {
  usePlayersFilterContext,
} from "@/application/Players/PlayersFilterContext";
import PlayersSortContextProvider, {
  usePlayersSortContext,
} from "@/application/Players/PlayersSortContext";
import { usePlayersContext } from "@/application/Players/PlayersContext";
import { usePlayersPageConfigurationContext } from "@/application/Players/PlayersPageConfigurationContext";
import Drawer from "@/ui/Drawer";
import Link from "@/ui/Link";
import FilterIcon from "@/assets/icons/filter.svg";
import RangeSlider from "@/ui/RangeSlider";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import Button from "@/ui/Button";
import PlayerPositionsCheckbox from "@/components/filters/PlayerPositionsCheckbox";
import ClubCheckbox from "@/components/ClubCheckbox";
import LeagueTeamCheckbox from "@/components/filters/LeagueTeamCheckbox";
import PlayersSortDrawer from "./PlayersSortDrawer";
import styles from "./PlayersFiltersDrawer.module.scss";

const PlayersFiltersDrawer = () => {
  const isMobile = useMediaQuery("(max-width: 768px)");

  const { isLeagueSpecificPlayersPage, leagueId } = usePlayersPageConfigurationContext();
  const { isSidebarOpen, filterCount, openSidebar, closeSidebar, clearFilter } =
    usePlayersContext();
  const { filterValues, onChangeValue, applyFilter } = usePlayersFilterContext();
  const { applySort, selectedSort } = usePlayersSortContext();

  const { t } = useTranslation();

  const [isSortDrawerOpen, setIsSortDrawerOpen] = useState(false);

  const isRangeActive = (value: { min: number; max: number }, min: number, max: number) =>
    value.min !== min || value.max !== max;

  const applyFilterHandler = () => {
    applyFilter();
    applySort();
    closeSidebar();
  };

  const clearFilterHandler = () => {
    clearFilter();
    closeSidebar();
  };

  return (
    <>
      <Link asButton icon={<FilterIcon />} onClick={openSidebar}>
        {t("players.filters.allFilters")} {filterCount > 0 ? `(${filterCount})` : ""}
      </Link>
      <Drawer
        title={t("players.filters.filters")}
        isOpen={isSidebarOpen}
        onClose={closeSidebar}
        noPadding
        footer={
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <Link asButton onClick={clearFilterHandler}>
              {t("players.filters.clearAll")}
            </Link>
            <Button onClick={applyFilterHandler}>{t("players.filters.applyFilters")}</Button>
          </div>
        }
      >
        {isMobile && (
          <Drawer.Button
            title={t("players.sorter.sortBy")}
            onClick={() => setIsSortDrawerOpen(true)}
            value={
              selectedSort && <span className={styles.sortButtonLabel}>{selectedSort?.label}</span>
            }
          />
        )}
        <Drawer.Section title={t("players.filters.clubsLabel")} withTopSpace defaultOpen={filterValues.clubs.length > 0}>
          <ClubCheckbox
            value={filterValues.clubs}
            onChange={onChangeValue("clubs")}
            leagueId={leagueId}
          />
        </Drawer.Section>
        <Drawer.Section title={t("players.filters.positionLabel")} withBottomSpace withTopSpace defaultOpen={filterValues.position.length > 0}>
          <PlayerPositionsCheckbox
            value={filterValues.position}
            onChange={onChangeValue("position")}
          />
        </Drawer.Section>
        <Drawer.Section title={t("players.filters.totalScoreLabel")} defaultOpen={isRangeActive(filterValues.totalScore, PlayersFilterConstants.TOTAL_SCORE_MIN, PlayersFilterConstants.TOTAL_SCORE_MAX)}>
          <RangeSlider
            value={filterValues.totalScore}
            onChange={onChangeValue("totalScore")}
            step={0.1}
            min={PlayersFilterConstants.TOTAL_SCORE_MIN}
            max={PlayersFilterConstants.TOTAL_SCORE_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title={t("players.filters.baseScoreLabel")} defaultOpen={isRangeActive(filterValues.baseScore, PlayersFilterConstants.BASE_SCORE_MIN, PlayersFilterConstants.BASE_SCORE_MAX)}>
          <RangeSlider
            value={filterValues.baseScore}
            onChange={onChangeValue("baseScore")}
            step={0.1}
            min={PlayersFilterConstants.BASE_SCORE_MIN}
            max={PlayersFilterConstants.BASE_SCORE_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title={t("players.filters.appearancesLabel")} defaultOpen={isRangeActive(filterValues.appearances, PlayersFilterConstants.APPEARANCES_MIN, PlayersFilterConstants.APPEARANCES_MAX)}>
          <RangeSlider
            value={filterValues.appearances}
            onChange={onChangeValue("appearances")}
            min={PlayersFilterConstants.APPEARANCES_MIN}
            max={PlayersFilterConstants.APPEARANCES_MAX}
          />
        </Drawer.Section>
        {isLeagueSpecificPlayersPage && leagueId && (
          <Drawer.Section title={t("players.filters.teamLabel")} withTopSpace defaultOpen={filterValues.teams.length > 0 || filterValues.withoutTeam}>
            <LeagueTeamCheckbox
              leagueId={leagueId}
              value={filterValues.teams}
              onChange={onChangeValue("teams")}
              withoutTeam={filterValues.withoutTeam}
              onWithoutTeamChange={onChangeValue("withoutTeam")}
            />
          </Drawer.Section>
        )}
        {isLeagueSpecificPlayersPage && (
          <Drawer.Section title={t("players.filters.priceLabel")} defaultOpen={isRangeActive(filterValues.price, PlayersFilterConstants.PRICE_MIN, PlayersFilterConstants.PRICE_MAX)}>
            <RangeSlider
              value={filterValues.price}
              onChange={onChangeValue("price")}
              min={PlayersFilterConstants.PRICE_MIN}
              max={PlayersFilterConstants.PRICE_MAX}
            />
          </Drawer.Section>
        )}
        {!isLeagueSpecificPlayersPage && (
          <Drawer.Section title={t("players.filters.numberOfTeamsLabel")} defaultOpen={isRangeActive(filterValues.teamsCount, PlayersFilterConstants.TEAMS_COUNT_MIN, PlayersFilterConstants.TEAMS_COUNT_MAX)}>
            <RangeSlider
              value={filterValues.teamsCount}
              onChange={onChangeValue("teamsCount")}
              min={PlayersFilterConstants.TEAMS_COUNT_MIN}
              max={PlayersFilterConstants.TEAMS_COUNT_MAX}
            />
          </Drawer.Section>
        )}
      </Drawer>
      {isMobile && (
        <PlayersSortDrawer isOpen={isSortDrawerOpen} close={() => setIsSortDrawerOpen(false)} />
      )}
    </>
  );
};

export default () => (
  <PlayersSortContextProvider>
    <PlayersFilterContextProvider>
      <PlayersFiltersDrawer />
    </PlayersFilterContextProvider>
  </PlayersSortContextProvider>
);
