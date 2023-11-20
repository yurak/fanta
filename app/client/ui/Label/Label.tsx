import React from "react";
import cn from "classnames";
import styles from "./Label.module.scss";

const Label = ({
  children,
  icon,
  type = "default",
}: {
  children: React.ReactNode;
  icon?: React.ReactNode;
  type?: "default" | "alert" | "error" | "success" | "new";
}) => {
  return (
    <span
      className={cn(styles.label, {
        [styles.alert]: type === "alert",
        [styles.error]: type === "error",
        [styles.success]: type === "success",
        [styles.new]: type === "new",
      })}
    >
      {icon && <span className={styles.icon}>{icon}</span>}
      {children}
    </span>
  );
};

export default Label;
