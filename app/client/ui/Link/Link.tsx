import React from "react";
import cn from "classnames";
import styles from "./Link.module.scss";

const Link = ({
  children,
  to,
  size = "large",
}: {
  children: React.ReactNode,
  to: string,
  size?: "small" | "large",
}) => {
  return (
    <a
      className={cn(styles.link, {
        [styles.small]: size === "small",
        [styles.large]: size === "large",
      })}
      href={to}
    >
      {children}
    </a>
  );
};

export default Link;
