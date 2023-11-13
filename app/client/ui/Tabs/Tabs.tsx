import React from "react";
import cn from "classnames";
import styles from "./Tabs.module.scss";

export interface ITab<ID> extends Record<string, unknown> {
  id: ID;
  name: string;
  icon?: React.ReactNode;
}

const Tabs = <ID extends any, Tab extends ITab<ID>>({
  tabs,
  active,
  onChange,
  nameRender,
}: {
  tabs: Tab[];
  active: ID;
  onChange: (active: ID) => void;
  nameRender?: (tab: Tab) => React.ReactNode;
}) => {
  return (
    <div className={styles.tabs}>
      {tabs.map((tab) => (
        <div
          key={String(tab.id)}
          className={cn(styles.item, {
            [styles.activeItem]: active === tab.id,
          })}
          onClick={() => onChange(tab.id)}
        >
          {tab.icon && <div className={styles.icon}>{tab.icon}</div>}
          <div className={styles.name}>
            {typeof nameRender === "function" ? nameRender(tab) : tab.name}
          </div>
        </div>
      ))}
    </div>
  );
};

export default Tabs;
