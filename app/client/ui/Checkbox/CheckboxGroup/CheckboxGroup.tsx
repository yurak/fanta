import { useMemo } from "react";
import Checkbox from "../Checkbox";
import styles from "./CheckboxGroup.module.scss";

const CheckboxGroup = <Option extends object, Value extends string | number>({
  options,
  value,
  onChange,
  formatOptionLabel,
  getOptionValue,
}: {
  options: Option[],
  value: Value[],
  onChange: (value: Value[]) => void,
  formatOptionLabel: (option: Option) => React.ReactNode,
  getOptionValue: (option: Option) => Value,
}) => {
  const _options = useMemo(
    () =>
      options.map((option) => ({
        ...option,
        _value: getOptionValue(option),
        _label: formatOptionLabel(option),
      })),
    [options]
  );

  const onChangeHandler = (optionId: Value) => (optionValue: boolean) => {
    if (optionValue) {
      onChange([...new Set([...value, optionId])]);
    } else {
      onChange(value.filter((v) => optionId !== v));
    }
  };

  return (
    <div className={styles.group}>
      {_options.map((option) => (
        <div key={option._value}>
          <Checkbox
            label={option._label}
            checked={value.includes(option._value)}
            onChange={onChangeHandler(option._value)}
            block
          />
        </div>
      ))}
    </div>
  );
};

export default CheckboxGroup;
