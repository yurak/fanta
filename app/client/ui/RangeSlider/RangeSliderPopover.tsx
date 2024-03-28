import { isArrayEquals } from "@/helpers/isArrayEquals";
import PopoverInput from "../PopoverInput";
import RangeSlider, { IProps as IRangeSliderProps } from "./RangeSlider";

interface IProps extends IRangeSliderProps {
  label: string,
  valueLabel?: string,
}

const RangeSliderPopover = ({ label, valueLabel = label, ...sliderProps }: IProps) => {
  const selectedLabel = isArrayEquals(sliderProps.value, [sliderProps.min, sliderProps.max])
    ? null
    : `${valueLabel}: ${sliderProps.value[0]}-${sliderProps.value[1]}`;

  return (
    <PopoverInput
      label={label}
      selectedLabel={selectedLabel}
      clearValue={() => sliderProps.onChange([sliderProps.min, sliderProps.max])}
    >
      <RangeSlider {...sliderProps} />
    </PopoverInput>
  );
};

export default RangeSliderPopover;
