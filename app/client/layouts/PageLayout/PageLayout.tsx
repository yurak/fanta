import React from "react";
import cn from "classnames";
import styles from "./PageLayout.module.scss";

const PageLayout = ({
  children,
  withSidebar,
}: {
  children: React.ReactNode,
  withSidebar?: boolean,
}) => {
  return (
    <div
      className={cn(styles.layout, {
        [styles.withSidebar]: withSidebar,
      })}
    >
      {children}
    </div>
  );
};

export default PageLayout;
