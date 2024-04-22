import { useMemo } from "react";
import { Positions } from "@/domain/Positions";
import { CheckboxGroup } from "@/ui/Checkbox";
import PopoverInput from "@/ui/PopoverInput";
import { Position } from "@/interfaces/Position";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { useAppContext } from "@/application/AppContext";
import styles from "./PlayerPositionsCheckbox.module.scss";

interface IProps {
  value: Position[],
  onChange: (value: Position[]) => void,
}

const PlayerPositionsCheckbox = ({ value, onChange }: IProps) => {
  const options = Object.values(Position).map((option) => ({ id: option }));

  return (
    <CheckboxGroup
      options={options}
      value={value}
      onChange={onChange}
      getOptionValue={(option) => option.id}
      formatOptionLabel={(option) => (
        <span className={styles.option}>
          <span>{Positions.getFullNameById(option.id)}</span>
          <span>
            <PlayerPositions position={option.id} outlined />
          </span>
        </span>
      )}
    />
  );
};

export const PlayerPositionsCheckboxPopover = (props: IProps) => {
  const { value, onChange } = props;

  const { italPositionNaming } = useAppContext();

  const selectedLabel = useMemo(() => {
    if (value.length === 0) {
      return null;
    }

    const positionLabel = Positions.getLabelById(value[0] as Position, italPositionNaming);

    if (value.length === 1) {
      return positionLabel;
    }

    return `${positionLabel} +${value.length - 1}`;
  }, [value, italPositionNaming]);

  return (
    <PopoverInput label="Position" selectedLabel={selectedLabel} clearValue={() => onChange([])}>
      <PlayerPositionsCheckbox {...props} />
    </PopoverInput>
  );
};

export default PlayerPositionsCheckbox;
