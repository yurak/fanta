import Link from "../Link";
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
  const isPristine = !selectedLabel;

  return (
    <Popover
      title={label}
      renderedReference={(props) => (
        <PopoverInputButton
          {...props}
          placeholder={label}
          selectedLabel={selectedLabel}
          clearValue={clearValue}
          isPristine={isPristine}
        />
      )}
      footer={
        <Link asButton disabled={isPristine} onClick={clearValue}>
          Clear
        </Link>
      }
    >
      {children}
    </Popover>
  );
};

export default PopoverInput;
