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
  return (
    <PopoverInput
      label="Position"
      value={positions}
      clearValue={() => setPositions([])}
      formatValue={(value) => {
        if (value.length === 0) {
          return null;
        }

        if (value.length === 1) {
          return value[0] ?? null;
        }

        return `${value[0]} +${value.length - 1}`;
      }}
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
