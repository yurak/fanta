import Popover from "../Popover";
import PopoverInputButton from "./PopoverInputButton";

const PopoverInput = ({
  label,
  selectedLabel,
  clearValue,
  children,
}: {
  label: string,
  selectedLabel?: string | null,
  clearValue: () => void,
  children: React.ReactNode,
}) => {
  return (
    <Popover
      title={label}
      renderedReference={(props) => (
        <PopoverInputButton
          {...props}
          placeholder={label}
          selectedLabel={selectedLabel}
          clearValue={clearValue}
        />
      )}
    >
      {children}
    </Popover>
  );
};

export default PopoverInput;
