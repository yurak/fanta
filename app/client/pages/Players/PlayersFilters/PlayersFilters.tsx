import PlayerPositionsCheckboxList from "@/components/PlayerPositionsCheckboxList";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { usePlayersFiltersContext } from "../PlayersFiltersContext";
import PlayersFiltersDrawer from "./PlayersFiltersDrawer";
import { RangeSliderPopover } from "@/ui/RangeSlider";

const PlayerFilters = () => {
  const {
    position,
    setPosition,
    totalScore,
    setTotalScore,
    baseScore,
    setBaseScore,
    appearances,
    setAppearances,
    price,
    setPrice,
  } = usePlayersFiltersContext();

  return (
    <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
      <PlayersFiltersDrawer />
      <PlayerPositionsCheckboxList positions={position} setPositions={setPosition} />
      <RangeSliderPopover
        min={PlayersFilterConstants.TOTAL_SCORE_MIN}
        max={PlayersFilterConstants.TOTAL_SCORE_MAX}
        value={totalScore}
        step={0.1}
        label="Total score"
        valueLabel="TS"
        onChange={setTotalScore}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.BASE_SCORE_MIN}
        max={PlayersFilterConstants.BASE_SCORE_MAX}
        step={0.1}
        value={baseScore}
        label="Base score"
        valueLabel="BS"
        onChange={setBaseScore}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.APPEARANCES_MIN}
        max={PlayersFilterConstants.APPEARANCES_MAX}
        value={appearances}
        label="Appearances"
        valueLabel="Apps"
        onChange={setAppearances}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.PRICE_MIN}
        max={PlayersFilterConstants.PRICE_MAX}
        value={price}
        label="Price"
        onChange={setPrice}
      />
    </div>
  );
};

export default PlayerFilters;
