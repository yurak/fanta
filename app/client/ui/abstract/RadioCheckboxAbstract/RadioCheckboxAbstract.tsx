import cn from "classnames";
import styles from "./RadioCheckboxAbstract.module.scss";

export interface IProps {
  type: "checkbox" | "radio",
  checked: boolean,
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void,
  icon: React.ReactNode,
  disabled?: boolean,
  block?: boolean,
  label?: React.ReactNode,
  indeterminate?: boolean,
}

const RadioCheckboxAbstract = ({
  disabled,
  checked,
  icon,
  onChange,
  block,
  label,
  indeterminate,
}: IProps) => {
  return (
    <label
      className={cn(styles.wrapper, {
        [styles.isActive]: checked || indeterminate,
        [styles.isDisabled]: disabled,
      })}
    >
      <input type="checkbox" checked={checked} disabled={disabled} onChange={onChange} />
      <span className={styles.iconWrapper}>
        <span className={styles.icon}>{icon}</span>
      </span>
      {label && (
        <span
          className={cn({
            [styles.block]: block,
          })}
        >
          {label}
        </span>
      )}
    </label>
  );
};

export default RadioCheckboxAbstract;
