import PlayerPositionsCheckboxList from "@/components/PlayerPositionsCheckboxList";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { RangeSliderPopover } from "@/ui/RangeSlider";
import PlayersFilterContextProvider, {
  usePlayersFilterContext,
} from "@/application/Players/PlayersFilterContext";

const PlayerFilters = () => {
  const { filterValues, onChangeValue } = usePlayersFilterContext();

  return (
    <>
      <PlayerPositionsCheckboxList
        positions={filterValues.position}
        setPositions={onChangeValue("position")}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.TOTAL_SCORE_MIN}
        max={PlayersFilterConstants.TOTAL_SCORE_MAX}
        value={filterValues.totalScore}
        step={0.1}
        label="Total score"
        valueLabel="TS"
        onChange={onChangeValue("totalScore")}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.BASE_SCORE_MIN}
        max={PlayersFilterConstants.BASE_SCORE_MAX}
        step={0.1}
        value={filterValues.baseScore}
        label="Base score"
        valueLabel="BS"
        onChange={onChangeValue("baseScore")}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.APPEARANCES_MIN}
        max={PlayersFilterConstants.APPEARANCES_MAX}
        value={filterValues.appearances}
        label="Appearances"
        valueLabel="Apps"
        onChange={onChangeValue("appearances")}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.PRICE_MIN}
        max={PlayersFilterConstants.PRICE_MAX}
        value={filterValues.price}
        label="Price"
        onChange={onChangeValue("price")}
      />
    </>
  );
};

export default () => (
  <PlayersFilterContextProvider shouldApplyOnValueChange>
    <PlayerFilters />
  </PlayersFilterContextProvider>
);
