import { isArrayEquals } from "@/helpers/isArrayEquals";
import PopoverInput from "../PopoverInput";
import RangeSlider, { IProps as IRangeSliderProps } from "./RangeSlider";

interface IProps extends IRangeSliderProps {
  label: string,
  valueLabel?: string,
}

const RangeSliderPopover = ({ max, min, value, onChange, label, valueLabel = label }: IProps) => {
  return (
    <PopoverInput
      label={label}
      value={value}
      clearValue={() => onChange([min, max])}
      formatValue={(value) => {
        if (isArrayEquals(value, [min, max])) {
          return null;
        }

        return `${valueLabel}: ${value[0]}-${value[1]}`;
      }}
    >
      <RangeSlider {...{ max, min, value, onChange }} />
    </PopoverInput>
  );
};

export default RangeSliderPopover;
