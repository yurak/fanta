import { useMemo } from "react";
import Checkbox from "../Checkbox";
import styles from "./CheckboxGroup.module.scss";

const CheckboxGroup = <Option extends object = object>({
  options,
  value,
  onChange,
  formatOptionLabel,
  getOptionValue,
}: {
  options: Option[],
  value: string[],
  onChange: (value: string[]) => void,
  formatOptionLabel: (option: Option) => React.ReactNode,
  getOptionValue: (option: Option) => string,
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

  const onChangeHandler = (optionId: string) => (optionValue: boolean) => {
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
