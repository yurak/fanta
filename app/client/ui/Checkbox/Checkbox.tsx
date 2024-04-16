import cn from "classnames";
import styles from "./Checkbox.module.scss";
import CheckedIcon from "@/assets/icons/checkbox.svg";
import IndeterminatedIcon from "@/assets/icons/indeterminate.svg";

const Checkbox = ({
  checked,
  onChange,
  indeterminate,
  label,
  disabled,
  block,
}: {
  checked: boolean,
  onChange: (checked: boolean) => void,
  indeterminate?: boolean,
  label?: React.ReactNode,
  disabled?: boolean,
  block?: boolean,
}) => {
  const isIndeterminate = !checked && indeterminate;

  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <label
      className={cn(styles.checkbox, {
        [styles.isActive]: checked || isIndeterminate,
        [styles.isDisabled]: disabled,
      })}
    >
      <input type="checkbox" checked={checked} disabled={disabled} onChange={onChangeHandler} />
      <span className={styles.checkboxToggle}>
        {checked && <CheckedIcon className={styles.icon} />}
        {isIndeterminate && <IndeterminatedIcon className={styles.icon} />}
      </span>
      {label && <span className={cn({ [styles.block]: block })}>{label}</span>}
    </label>
  );
};

export default Checkbox;
