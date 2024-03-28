import { useEffect, useState } from "react";
import Slider from "rc-slider";
import "rc-slider/assets/index.css";
import TooltipArrowIcon from "@/assets/icons/tooltipArrow.svg";
import styles from "./RangeSlider.module.scss";

const isArraysEqual = (array1: number[], array2: number[]) => {
  if (array1.length !== array2.length) {
    return false;
  }

  return array1.every((value, index) => array2[index] === value);
};

const RangeSlider = ({
  min,
  max,
  value,
  onChange,
}: {
  min: number,
  max: number,
  value: number[],
  onChange: (value: number[]) => void,
}) => {
  const [innerValue, setInnerValue] = useState<number[]>([min, max]);

  useEffect(() => {
    if (!isArraysEqual(value, innerValue)) {
      setInnerValue(value);
    }
  }, [value]);

  return (
    <div className={styles.container}>
      <Slider
        range
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
