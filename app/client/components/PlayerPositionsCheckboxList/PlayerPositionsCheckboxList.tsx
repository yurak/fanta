import { useMemo } from "react";
import { CheckboxGroup } from "@/ui/Checkbox";
import PopoverInput from "@/ui/PopoverInput";
import { PlayerPosition } from "@/interfaces/Player";
import PlayerPositions from "../PlayerPositions/PlayerPositions";
import styles from "./PlayerPositionsCheckboxList.module.scss";

const PlayerPositionsCheckboxList = ({
  positions,
  setPositions,
}: {
  positions: string[],
  setPositions: (value: string[]) => void,
}) => {
  const selectedLabel = useMemo(() => {
    if (positions.length === 0) {
      return null;
    }

    if (positions.length === 1) {
      return positions[0] ?? null;
    }

    return `${positions[0]} +${positions.length - 1}`;
  }, [positions]);

  return (
    <PopoverInput
      label="Position"
      selectedLabel={selectedLabel}
      clearValue={() => setPositions([])}
    >
      <CheckboxGroup
        options={Object.values(PlayerPosition).map((option) => ({ id: option }))}
        getOptionValue={(option) => option.id}
        formatOptionLabel={(option) => (
          <span className={styles.option}>
            <span>{option.id}</span>
            <span>
              <PlayerPositions positions={[option.id] as PlayerPosition[]} />
            </span>
          </span>
        )}
        value={positions}
        onChange={setPositions}
      />
    </PopoverInput>
  );
};

export default PlayerPositionsCheckboxList;
