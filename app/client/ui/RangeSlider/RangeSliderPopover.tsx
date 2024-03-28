import { isArrayEquals } from "@/helpers/isArrayEquals";
import PopoverInput from "../PopoverInput";
import RangeSlider, { IProps as IRangeSliderProps } from "./RangeSlider";

interface IProps extends IRangeSliderProps {
  label: string,
  valueLabel?: string,
}

const RangeSliderPopover = ({ label, valueLabel = label, ...sliderProps }: IProps) => {
  return (
    <PopoverInput
      label={label}
      value={sliderProps.value}
      clearValue={() => sliderProps.onChange([sliderProps.min, sliderProps.max])}
      formatValue={(value) => {
        if (isArrayEquals(value, [sliderProps.min, sliderProps.max])) {
          return null;
        }

        return `${valueLabel}: ${value[0]}-${value[1]}`;
      }}
    >
      <RangeSlider {...sliderProps} />
    </PopoverInput>
  );
};

export default RangeSliderPopover;
