import Popover from "../Popover";
import PopoverInputButton from "./PopoverInputButton";

const PopoverInput = <T extends null | string | number | string[] | number[]>({
  label,
  value,
  clearValue,
  formatValue,
}: {
  label: string,
  value: T,
  clearValue: () => void,
  formatValue: (value: T) => string | null,
  isActive?: (value: T) => boolean,
}) => {
  return (
    <Popover
      title={label}
      renderedReference={(props) => (
        <PopoverInputButton
          {...props}
          placeholder={label}
          value={formatValue(value)}
          clearValue={clearValue}
        />
      )}
    >
      Positions
    </Popover>
  );
};

export default PopoverInput;
