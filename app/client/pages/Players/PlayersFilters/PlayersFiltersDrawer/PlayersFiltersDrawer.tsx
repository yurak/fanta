import PlayersFilterContextProvider, {
  usePlayersFilterContext,
} from "@/application/Players/PlayersFilterContext";
import { usePlayersContext } from "@/application/Players/PlayersContext";
import Drawer from "@/ui/Drawer";
import Link from "@/ui/Link";
import FilterIcon from "@/assets/icons/filter.svg";
import RangeSlider from "@/ui/RangeSlider";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import Button from "@/ui/Button";
import PlayerPositionsCheckbox from "@/components/filters/PlayerPositionsCheckbox";

const PlayersFiltersDrawer = () => {
  const { isSidebarOpen, openSidebar, closeSidebar, clearFilter } = usePlayersContext();
  const { filterValues, onChangeValue, applyFilter } = usePlayersFilterContext();

  const applyFilterHandler = () => {
    applyFilter();
    closeSidebar();
  };

  const clearFilterHandler = () => {
    clearFilter();
    closeSidebar();
  };

  return (
    <>
      <Link asButton icon={<FilterIcon />} onClick={openSidebar}>
        All filters
      </Link>
      <Drawer
        title="Filters"
        isOpen={isSidebarOpen}
        onClose={closeSidebar}
        footer={
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <Link asButton onClick={clearFilterHandler}>
              Clear all
            </Link>
            <Button onClick={applyFilterHandler}>Apply filter</Button>
          </div>
        }
      >
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
            min={PlayersFilterConstants.TOTAL_SCORE_MIN}
            max={PlayersFilterConstants.TOTAL_SCORE_MAX}
          />
        </Drawer.Section>
        <Drawer.Section title="Base score">
          <RangeSlider
            value={filterValues.baseScore}
            onChange={onChangeValue("baseScore")}
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
        <Drawer.Section title="Price">
          <RangeSlider
            value={filterValues.price}
            onChange={onChangeValue("price")}
            min={PlayersFilterConstants.PRICE_MIN}
            max={PlayersFilterConstants.PRICE_MAX}
          />
        </Drawer.Section>
      </Drawer>
    </>
  );
};

export default () => (
  <PlayersFilterContextProvider>
    <PlayersFiltersDrawer />
  </PlayersFilterContextProvider>
);
