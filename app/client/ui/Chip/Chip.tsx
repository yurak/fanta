import React from "react";
import cn from "classnames";
import styles from "./Chip.module.scss";

const Chip = ({
  children,
  onClick,
  disabled,
  asDisabled,
  selected,
  size = "small",
}: {
  children: React.ReactNode,
  onClick: () => void,
  disabled?: boolean,
  asDisabled?: boolean,
  selected?: boolean,
  size?: "small" | "medium",
}) => {
  return (
    <button
      className={cn(styles.chip, {
        [styles.selected]: selected,
        [styles.medium]: size === "medium",
        [styles.disabled]: asDisabled,
      })}
      type="button"
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
};

export default Chip;
