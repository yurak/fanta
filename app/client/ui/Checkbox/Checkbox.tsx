import cn from "classnames";
import styles from "./Checkbox.module.scss";
import CheckboxIcon from "@/assets/icons/checkbox.svg";

const Checkbox = ({
  checked,
  onChange,
  label,
  disabled,
}: {
  checked: boolean,
  onChange: (checked: boolean) => void,
  label?: string,
  disabled?: boolean,
}) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <label className={styles.checkbox}>
      <input type="checkbox" checked={checked} disabled={disabled} onChange={onChangeHandler} />
      <span
        className={cn(styles.checkboxToggle, {
          [styles.isChecked]: checked,
          [styles.isDisabled]: disabled,
        })}
      >
        {checked && <CheckboxIcon className={styles.icon} />}
      </span>
      {label && <span>{label}</span>}
    </label>
  );
};

export default Checkbox;
