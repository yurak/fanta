import React from "react";
import cn from "classnames";
import Skeleton from "react-loading-skeleton";
import EmptyState from "@/ui/EmptyState";
import styles from "./DataList.module.scss";

const LoadingSkeleton = ({
  skeletonRender = () => <Skeleton />,
  items = 5,
}: {
  skeletonRender?: () => React.ReactNode,
  items?: number,
}) => {
  return Array.from({ length: items }).map((_, index) => (
    <div key={index} className={styles.item}>
      {skeletonRender()}
    </div>
  ));
};

const DataList = <DataItem extends object = object>({
  dataSource,
  renderItem,
  itemKey,
  itemLink,
  itemClassName,
  isLoading,
  skeletonRender,
  skeletonItems,
  emptyState = { title: "No data" },
}: {
  dataSource: DataItem[],
  renderItem: (item: DataItem) => React.ReactNode,
  itemKey: (item: DataItem) => string | number,
  itemLink?: (item: DataItem) => string,
  itemClassName?: string,
  isLoading?: boolean,
  skeletonRender?: () => React.ReactNode,
  skeletonItems?: number,
  emptyState?: {
    title: string,
    description?: string,
  },
}) => {
  return (
    <div className={styles.list}>
      {isLoading ? (
        <LoadingSkeleton skeletonRender={skeletonRender} items={skeletonItems} />
      ) : (
        <>
          {dataSource.length > 0 ? (
            dataSource.map((dataItem) => (
              <div
                key={itemKey(dataItem)}
                className={cn(styles.item, styles.hoverableItem, itemClassName)}
              >
                {itemLink && <a href={itemLink(dataItem)} className={styles.itemLink} />}
                {renderItem(dataItem)}
              </div>
            ))
          ) : (
            <div className={styles.emptyState}>
              <EmptyState title={emptyState.title} description={emptyState.description} />
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default DataList;
