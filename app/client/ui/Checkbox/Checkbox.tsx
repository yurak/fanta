import cn from "classnames";
import styles from "./Checkbox.module.scss";
import CheckboxIcon from "@/assets/icons/checkbox.svg";

const Checkbox = ({
  checked,
  onChange,
  label,
  disabled,
  block,
}: {
  checked: boolean,
  onChange: (checked: boolean) => void,
  label?: React.ReactNode,
  disabled?: boolean,
  block?: boolean,
}) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <label
      className={cn(styles.checkbox, {
        [styles.isChecked]: checked,
        [styles.isDisabled]: disabled,
      })}
    >
      <input type="checkbox" checked={checked} disabled={disabled} onChange={onChangeHandler} />
      <span className={styles.checkboxToggle}>
        {checked && <CheckboxIcon className={styles.icon} />}
      </span>
      {label && <span className={cn({ [styles.block]: block })}>{label}</span>}
    </label>
  );
};

export default Checkbox;
