import { useEffect, useState } from "react";
import Slider from "rc-slider";
import "rc-slider/assets/index.css";
import TooltipArrowIcon from "@/assets/icons/tooltipArrow.svg";
import styles from "./RangeSlider.module.scss";

export type RangeSliderValueType = {
  min: number,
  max: number,
};

export interface IProps {
  min: number,
  max: number,
  value: RangeSliderValueType,
  onChange: (value: RangeSliderValueType) => void,
  step?: number,
}

const RangeSlider = ({ min, max, value, onChange, step = 1 }: IProps) => {
  const [innerValue, setInnerValue] = useState<number[]>([value.min, value.max]);

  useEffect(() => {
    if (value.min !== innerValue[0] || value.max !== innerValue[1]) {
      setInnerValue([value.min, value.max]);
    }
  }, [value]);

  return (
    <div className={styles.container}>
      <Slider
        range
        step={step}
        min={min}
        max={max}
        className={styles.slider}
        classNames={{ rail: styles.rail, track: styles.track, handle: styles.handle }}
        value={innerValue}
        onChangeComplete={(value) => {
          onChange({
            min: value[0],
            max: value[1],
          });
        }}
        onChange={(value) => {
          setInnerValue(value as number[]);
        }}
      />
      {innerValue.map((value, index) => {
        const percentage = Math.max(0, Math.min(100, (value / max) * 100));

        return (
          <span
            key={`${value}-${index}`}
            className={styles.valueTooltip}
            style={{
              left: `${percentage}%`,
            }}
          >
            {value}
            <TooltipArrowIcon className={styles.valueTooltipIcon} />
          </span>
        );
      })}
    </div>
  );
};

export default RangeSlider;
