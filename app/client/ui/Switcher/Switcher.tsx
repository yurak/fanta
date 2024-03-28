import React from "react";
import cn from "classnames";
import styles from "./Switcher.module.scss";

const Switcher = ({
  checked,
  onChange,
  label,
}: {
  checked: boolean,
  onChange: (checked: boolean) => void,
  label?: string,
}) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <label
      className={cn(styles.switcher, {
        [styles.isChecked]: checked,
      })}
    >
      <input type="checkbox" checked={checked} onChange={onChangeHandler} />
      <span className={styles.switcherToggle} />
      {label && <span>{label}</span>}
    </label>
  );
};

export default Switcher;
