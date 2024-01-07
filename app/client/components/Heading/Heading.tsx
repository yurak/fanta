import React from "react";
import cn from "classnames";
import styles from "./Heading.module.scss";

const Heading = ({
  title,
  titleIcon,
  tag: TitleTag = "h3",
  description,
  noSpace,
}: {
  title: string,
  titleIcon?: React.ReactNode,
  tag?: "h3" | "h4",
  description?: string,
  noSpace?: boolean,
}) => (
  <div className={cn(styles.heading, { [styles.noSpace]: noSpace })}>
    <TitleTag
      className={cn(styles.title, {
        [styles.h3]: TitleTag === "h3",
        [styles.h4]: TitleTag === "h4",
      })}
    >
      {titleIcon && <span className={styles.titleIcon}>{titleIcon}</span>}
      {title}
    </TitleTag>
    {description && <p className={styles.description}>{description}</p>}
  </div>
);

export default Heading;
