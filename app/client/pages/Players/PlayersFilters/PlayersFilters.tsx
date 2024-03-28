import { useState } from "react";
import PlayerPositionsCheckboxList from "@/components/PlayerPositionsCheckboxList";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { usePlayersFiltersContext } from "../PlayersFiltersContext";
import PlayersFiltersDrawer from "./PlayersFiltersDrawer";
import { RangeSliderPopover } from "@/ui/RangeSlider";

const PlayerFilters = () => {
  const { position, setPosition } = usePlayersFiltersContext();

  const [totalScore, setTotalScore] = useState([
    PlayersFilterConstants.TOTAL_SCORE_MIN,
    PlayersFilterConstants.TOTAL_SCORE_MAX,
  ]);

  const [baseScore, setBaseScore] = useState([
    PlayersFilterConstants.BASE_SCORE_MIN,
    PlayersFilterConstants.BASE_SCORE_MAX,
  ]);

  const [appearances, setAppearances] = useState([
    PlayersFilterConstants.APPEARANCES_MIN,
    PlayersFilterConstants.APPEARANCES_MAX,
  ]);

  const [price, setPrice] = useState([
    PlayersFilterConstants.PRICE_MIN,
    PlayersFilterConstants.PRICE_MAX,
  ]);

  return (
    <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
      <PlayersFiltersDrawer />
      <PlayerPositionsCheckboxList positions={position} setPositions={setPosition} />
      <RangeSliderPopover
        min={PlayersFilterConstants.TOTAL_SCORE_MIN}
        max={PlayersFilterConstants.TOTAL_SCORE_MAX}
        value={totalScore}
        label="Total score"
        valueLabel="TS"
        onChange={setTotalScore}
      />
      <RangeSliderPopover
        min={PlayersFilterConstants.BASE_SCORE_MIN}
        max={PlayersFilterConstants.BASE_SCORE_MAX}
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
