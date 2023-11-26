import React from "react";
import ReactSelect, {
  ActionMeta,
  FormatOptionLabelMeta,
  GetOptionValue,
  OnChangeValue,
  PropsValue,
  components,
} from "react-select";
import Skeleton from "react-loading-skeleton";
import arrowDown from "../../../assets/images/icons/arrow_down.svg";
import { useIsClient } from "../../hooks/useIsClient";
import styles from "./Select.module.scss";

const Select = <Option extends unknown, IsMulti extends boolean = false>({
  value,
  onChange,
  options,
  placeholder,
  isLoading,
  icon,
  formatOptionLabel,
  getOptionValue,
}: {
  options: Option[];
  value: PropsValue<Option>;
  onChange: (newValue: OnChangeValue<Option, IsMulti>, actionMeta: ActionMeta<Option>) => void;
  placeholder?: string;
  isLoading?: boolean;
  icon?: React.ReactNode;
  formatOptionLabel?: (
    data: Option,
    formatOptionLabelMeta: FormatOptionLabelMeta<Option>
  ) => React.ReactNode;
  getOptionValue?: GetOptionValue<Option>;
}) => {
  // TODO: temporary solution, need to fix working with ssr
  const isClient = useIsClient();
  if (!isClient || isLoading) {
    return <Skeleton height={36} />;
  }

  return (
    <ReactSelect
      styles={{
        control: (styles) => ({
          ...styles,
          minHeight: 40,
        }),
        valueContainer: (styles) => ({
          ...styles,
          ...(icon && {
            paddingLeft: 5,
          }),
        }),
      }}
      classNames={{
        control: () => styles.select,
      }}
      options={options}
      isSearchable={false}
      placeholder={placeholder}
      formatOptionLabel={formatOptionLabel}
      getOptionValue={getOptionValue}
      onChange={onChange}
      value={value}
      components={{
        IndicatorSeparator: null,
        DropdownIndicator: () => (
          <span className={styles.dropdownIndicator}>
            <img src={arrowDown} width={10} />
          </span>
        ),
        ValueContainer: (props) => (
          <>
            {icon && <span className={styles.valueIcon}>{icon}</span>}
            {components.ValueContainer(props)}
          </>
        ),
      }}
    />
  );
};

export default Select;
