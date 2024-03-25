import PlayerPositionsCheckboxList from "@/components/PlayerPositionsCheckboxList";
import { usePlayersFiltersContext } from "../PlayersFiltersContext";

const PlayerFilters = () => {
  const { position, setPosition } = usePlayersFiltersContext();

  return (
    <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
      <PlayerPositionsCheckboxList positions={position} setPositions={setPosition} />
    </div>
  );
};

export default PlayerFilters;
