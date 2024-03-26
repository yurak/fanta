import React from "react";
import cn from "classnames";
import styles from "./Link.module.scss";

const Link = ({
  children,
  size,
  icon,
  ...props
}: {
  children: React.ReactNode,
  size?: "small" | "large",
  icon?: React.ReactNode,
} & (
  | {
      to: string,
      asButton?: false,
    }
  | {
      asButton: true,
      onClick: () => void,
    }
)) => {
  const className = cn(styles.link, {
    [styles.small]: size === "small",
    [styles.large]: size === "large",
  });

  const content = (
    <>
      {icon && <span className={styles.icon}>{icon}</span>}
      <span className={styles.name}>{children}</span>
    </>
  );

  if (props.asButton) {
    return (
      <button className={cn(className, styles.button)} onClick={props.onClick}>
        {content}
      </button>
    );
  }

  return (
    <a className={className} href={props.to}>
      {content}
    </a>
  );
};

export default Link;
