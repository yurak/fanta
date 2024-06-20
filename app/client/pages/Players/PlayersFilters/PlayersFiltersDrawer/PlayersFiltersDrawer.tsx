import { useState } from "react";
import { useMediaQuery } from "usehooks-ts";
import PlayersFilterContextProvider, {
  usePlayersFilterContext,
} from "@/application/Players/PlayersFilterContext";
import PlayersSortContextProvider, {
  usePlayersSortContext,
} from "@/application/Players/PlayersSortContext";
import { usePlayersContext } from "@/application/Players/PlayersContext";
import Drawer from "@/ui/Drawer";
import Link from "@/ui/Link";
import FilterIcon from "@/assets/icons/filter.svg";
import RangeSlider from "@/ui/RangeSlider";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import Button from "@/ui/Button";
import PlayerPositionsCheckbox from "@/components/filters/PlayerPositionsCheckbox";
import ClubCheckbox from "@/components/ClubCheckbox";
import PlayersSortDrawer from "./PlayersSortDrawer";
import styles from "./PlayersFiltersDrawer.module.scss";

const PlayersFiltersDrawer = () => {
  const isMobile = useMediaQuery("(max-width: 768px)");

  const { isSidebarOpen, filterCount, openSidebar, closeSidebar, clearFilter } =
    usePlayersContext();
  const { filterValues, onChangeValue, applyFilter } = usePlayersFilterContext();
  const { applySort, selectedSort } = usePlayersSortContext();

  const [isSortDrawerOpen, setIsSortDrawerOpen] = useState(false);

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
        All filters {filterCount > 0 ? `(${filterCount})` : ""}
      </Link>
      <Drawer
        title="Filters"
        isOpen={isSidebarOpen}
        onClose={closeSidebar}
        noPadding
        footer={
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <Link asButton onClick={clearFilterHandler}>
              Clear all
            </Link>
            <Button onClick={applyFilterHandler}>Apply filter</Button>
          </div>
        }
      >
        {isMobile && (
          <Drawer.Button
            title="Sort by"
            onClick={() => setIsSortDrawerOpen(true)}
            value={
              selectedSort && <span className={styles.sortButtonLabel}>{selectedSort?.label}</span>
            }
          />
        )}
        <Drawer.Section title="Clubs">
          <ClubCheckbox value={filterValues.clubs} onChange={onChangeValue("clubs")} />
        </Drawer.Section>
        <Drawer.Section title="Position">
          <PlayerPositionsCheckbox
            value={filterValues.position}
            onChange={onChangeValue("position")}
          />
        </Drawer.Section>
        <Drawer.Section title="Total score">
          <RangeSlider
            value={filterValues.totalScore}
            onChange={onChangeValue("totalScore")}
            step={0.1}
            min={PlayersFilterConstants.TOTAL_SCORE_MIN}
            max={PlayersFilterConstants.TOTAL_SCORE_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title="Base score">
          <RangeSlider
            value={filterValues.baseScore}
            onChange={onChangeValue("baseScore")}
            step={0.1}
            min={PlayersFilterConstants.BASE_SCORE_MIN}
            max={PlayersFilterConstants.BASE_SCORE_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title="Appearances">
          <RangeSlider
            value={filterValues.appearances}
            onChange={onChangeValue("appearances")}
            min={PlayersFilterConstants.APPEARANCES_MIN}
            max={PlayersFilterConstants.APPEARANCES_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title="# of teams">
          <RangeSlider
            value={filterValues.teamsCount}
            onChange={onChangeValue("teamsCount")}
            min={PlayersFilterConstants.TEAMS_COUNT_MIN}
            max={PlayersFilterConstants.TEAMS_COUNT_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title="Price">
          <RangeSlider
            value={filterValues.price}
            onChange={onChangeValue("price")}
            min={PlayersFilterConstants.PRICE_MIN}
            max={PlayersFilterConstants.PRICE_MAX}
          />
        </Drawer.Section>
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
