import { useMemo } from "react";
import { CheckboxGroup } from "@/ui/Checkbox";
import PopoverInput from "@/ui/PopoverInput";
import { PlayerPosition } from "@/interfaces/Player";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import styles from "./PlayerPositionsCheckbox.module.scss";

interface IProps {
  value: string[],
  onChange: (value: string[]) => void,
}

const PlayerPositionsCheckbox = ({ value, onChange }: IProps) => {
  const options = Object.values(PlayerPosition).map((option) => ({ id: option }));

  return (
    <CheckboxGroup
      options={options}
      value={value}
      onChange={onChange}
      getOptionValue={(option) => option.id}
      formatOptionLabel={(option) => (
        <span className={styles.option}>
          <span>{option.id}</span>
          <span>
            <PlayerPositions positions={[option.id] as PlayerPosition[]} />
          </span>
        </span>
      )}
    />
  );
};

export const PlayerPositionsCheckboxPopover = (props: IProps) => {
  const { value, onChange } = props;

  const selectedLabel = useMemo(() => {
    if (value.length === 0) {
      return null;
    }

    if (value.length === 1) {
      return value[0] ?? null;
    }

    return `${value[0]} +${value.length - 1}`;
  }, [value]);

  return (
    <PopoverInput label="Position" selectedLabel={selectedLabel} clearValue={() => onChange([])}>
      <PlayerPositionsCheckbox {...props} />
    </PopoverInput>
  );
};

export default PlayerPositionsCheckbox;
