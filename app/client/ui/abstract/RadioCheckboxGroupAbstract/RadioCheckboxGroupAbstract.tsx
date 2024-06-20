import { useMemo } from "react";
import { IRadioCheckboxAbstractProps } from "../RadioCheckboxAbstract";
import styles from "./RadioCheckboxGroupAbstract.module.scss";

interface IComponentType extends Omit<IRadioCheckboxAbstractProps, "onChange" | "type" | "icon"> {
  onChange: (value: boolean) => void,
}

export interface IProps<Option extends object, ID extends string | number | object | null> {
  options: Option[],
  onChange: (id: ID, checked: boolean) => void,
  formatOptionLabel: (option: Option) => React.ReactNode,
  getOptionValue: (option: Option) => NonNullable<ID>,
  getOptionKey: (option: Option) => string | number,
  isChecked: (id: NonNullable<ID>) => boolean,
  Component: React.ComponentType<IComponentType>,
}

const RadioCheckboxGroupAbstract = <
  Option extends object,
  ID extends string | number | object | null
>({
  options,
  onChange,
  formatOptionLabel,
  getOptionValue,
  getOptionKey,
  Component,
  isChecked,
}: IProps<Option, ID>) => {
  const _options = useMemo(
    () =>
      options.map((option) => ({
        ...option,
        _value: getOptionValue(option),
        _label: formatOptionLabel(option),
        _key: getOptionKey(option),
      })),
    [options]
  );

  const onChangeHandler = (optionId: ID) => (checked: boolean) => {
    onChange(optionId, checked);
  };

  return (
    <div className={styles.group}>
      {_options.map((option) => (
        <div key={option._key}>
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
