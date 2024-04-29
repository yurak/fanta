import cn from "classnames";
import styles from "./Button.module.scss";

const Button = ({
  variant = "primary",
  size = "medium",
  block,
  disabled,
  children,
  onClick,
}: {
  variant?: "primary" | "secondary",
  size?: "small" | "medium" | "large",
  block?: boolean,
  disabled?: boolean,
  children: React.ReactNode,
  onClick: () => void,
}) => (
  <button
    className={cn(styles.button, {
      [styles.secondary]: variant === "secondary",
      [styles.small]: size === "small",
      [styles.large]: size === "large",
      [styles.disabled]: disabled,
      [styles.block]: block,
    })}
    disabled={disabled}
    onClick={onClick}
  >
    {children}
  </button>
);

export default Button;
