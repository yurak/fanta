import React from "react";
import styles from "./PageLayout.module.scss";

const PageLayout = ({ children }: { children: React.ReactNode }) => {
  return <div className={styles.layout}>{children}</div>;
};

export default PageLayout;
