import PopoverInput from "../PopoverInput";
import RangeSlider, { IProps as IRangeSliderProps } from "./RangeSlider";
import { useMemo } from "react";

interface IProps extends IRangeSliderProps {
  label: string,
  valueLabel?: string,
}

const RangeSliderPopover = ({ label, valueLabel = label, ...sliderProps }: IProps) => {
  const selectedLabel = useMemo(() => {
    if (sliderProps.value.min === sliderProps.min && sliderProps.value.max === sliderProps.max) {
      return null;
    }

    return `${valueLabel}: ${sliderProps.value.min}-${sliderProps.value.max}`;
  }, [sliderProps.value, sliderProps.min, sliderProps.max]);

  return (
    <PopoverInput
      label={label}
      selectedLabel={selectedLabel}
      clearValue={() =>
        sliderProps.onChange({
          min: sliderProps.min,
          max: sliderProps.max,
        })
      }
    >
      <RangeSlider {...sliderProps} />
    </PopoverInput>
  );
};

export default RangeSliderPopover;
