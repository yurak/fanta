import React from "react";
import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import styles from "./Tabs.module.scss";

export interface ITab<ID> extends Record<string, unknown> {
  id: ID;
  name: string;
  icon?: React.ReactNode;
}

const TabsSkeleton = ({ items }: { items: number }) => {
  return Array.from({ length: items }).map((_, index) => (
    <div key={index} className={cn(styles.item, styles.skeletonItem)}>
      <Skeleton className={styles.skeletonIcon} inline />
      <Skeleton inline />
    </div>
  ));
};

const Tabs = <ID, Tab extends ITab<ID>>({
  tabs,
  active,
  onChange,
  nameRender,
  isLoading,
  skeletonItems = 6,
}: {
  tabs: Tab[];
  active: ID;
  onChange: (active: ID) => void;
  nameRender?: (tab: Tab) => React.ReactNode;
  isLoading?: boolean;
  skeletonItems?: number;
}) => {
  return (
    <div className={styles.tabs}>
      <div className={styles.tabsInner}>
        {isLoading ? (
          <TabsSkeleton items={skeletonItems} />
        ) : (
          tabs.map((tab) => (
            <div
              key={String(tab.id)}
              className={cn(styles.item, styles.itemHoverable, {
                [styles.activeItem]: active === tab.id,
              })}
              onClick={() => onChange(tab.id)}
            >
              {tab.icon && <div className={styles.icon}>{tab.icon}</div>}
              <div className={styles.name}>
                {typeof nameRender === "function" ? nameRender(tab) : tab.name}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Tabs;
