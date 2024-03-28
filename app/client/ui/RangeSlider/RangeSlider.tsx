import { useEffect, useState } from "react";
import Slider from "rc-slider";
import "rc-slider/assets/index.css";
import { isArrayEquals } from "@/helpers/isArrayEquals";
import TooltipArrowIcon from "@/assets/icons/tooltipArrow.svg";
import styles from "./RangeSlider.module.scss";

export interface IProps {
  min: number,
  max: number,
  value: number[],
  onChange: (value: number[]) => void,
  step?: number,
}

const RangeSlider = ({ min, max, value, onChange, step = 1 }: IProps) => {
  const [innerValue, setInnerValue] = useState<number[]>(value);

  useEffect(() => {
    if (!isArrayEquals(value, innerValue)) {
      setInnerValue(value);
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
          onChange(value as number[]);
        }}
        onChange={(value) => {
          setInnerValue(value as number[]);
        }}
      />
      {innerValue.map((value, index) => (
        <span
          key={`${value}-${index}`}
          className={styles.valueTooltip}
          style={{
            left: `${(value / max) * 100}%`,
          }}
        >
          {value}
          <TooltipArrowIcon className={styles.valueTooltipIcon} />
        </span>
      ))}
    </div>
  );
};

export default RangeSlider;
