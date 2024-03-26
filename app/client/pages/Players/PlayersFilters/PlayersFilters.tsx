import PlayerPositionsCheckboxList from "@/components/PlayerPositionsCheckboxList";
import { usePlayersFiltersContext } from "../PlayersFiltersContext";
import PlayersFiltersDrawer from "./PlayersFiltersDrawer";

const PlayerFilters = () => {
  const { position, setPosition } = usePlayersFiltersContext();

  return (
    <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
      <PlayersFiltersDrawer />
      <PlayerPositionsCheckboxList positions={position} setPositions={setPosition} />
    </div>
  );
};

export default PlayerFilters;
