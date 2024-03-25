import Popover from "../Popover";
import PopoverInputButton from "./PopoverInputButton";

const PopoverInput = <T extends null | string | number | string[] | number[] | boolean>({
  label,
  value,
  clearValue,
  formatValue,
  children,
}: {
  label: string,
  value: T,
  clearValue: () => void,
  formatValue: (value: T) => string | null,
  isActive?: (value: T) => boolean,
  children: React.ReactNode,
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
      {children}
    </Popover>
  );
};

export default PopoverInput;
