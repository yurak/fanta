import { useMemo } from "react";
import { IRadioCheckboxAbstractProps } from "../RadioCheckboxAbstract";
import styles from "./RadioCheckboxGroupAbstract.module.scss";

interface IComponentType extends Omit<IRadioCheckboxAbstractProps, "onChange" | "type" | "icon"> {
  onChange: (value: boolean) => void,
}

export interface IProps<Option extends object, ID extends string | number> {
  options: Option[],
  onChange: (id: ID, checked: boolean) => void,
  formatOptionLabel: (option: Option) => React.ReactNode,
  getOptionValue: (option: Option) => ID,
  isChecked: (id: ID) => boolean,
  Component: React.ComponentType<IComponentType>,
}

const RadioCheckboxGroupAbstract = <Option extends object, ID extends string | number>({
  options,
  onChange,
  formatOptionLabel,
  getOptionValue,
  Component,
  isChecked,
}: IProps<Option, ID>) => {
  const _options = useMemo(
    () =>
      options.map((option) => ({
        ...option,
        _value: getOptionValue(option),
        _label: formatOptionLabel(option),
      })),
    [options]
  );

  const onChangeHandler = (optionId: ID) => (checked: boolean) => {
    onChange(optionId, checked);
  };

  return (
    <div className={styles.group}>
      {_options.map((option) => (
        <div key={option._value}>
          <Component
            label={option._label}
            checked={isChecked(option._value)}
            onChange={onChangeHandler(option._value)}
            block
          />
        </div>
      ))}
    </div>
  );
};

export default RadioCheckboxGroupAbstract;
