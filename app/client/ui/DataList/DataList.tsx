import React from "react";
import cn from "classnames";
import Skeleton from "react-loading-skeleton";
import styles from "./DataList.module.scss";

const LoadingSkeleton = ({
  skeletonRender = () => <Skeleton />,
  items = 5,
}: {
  skeletonRender?: () => React.ReactNode;
  items?: number;
}) => {
  return Array.from({ length: items }).map((_, index) => (
    <div key={index} className={styles.item}>
      {skeletonRender()}
    </div>
  ));
};

const DataList = <DataItem extends {} = {}>({
  dataSource,
  renderItem,
  itemKey,
  itemLink,
  isLoading,
  skeletonRender,
  skeletonItems,
}: {
  dataSource: DataItem[];
  renderItem: (item: DataItem) => React.ReactNode;
  itemKey: (item: DataItem) => string | number;
  itemLink?: (item: DataItem) => string;
  isLoading?: boolean;
  skeletonRender?: () => React.ReactNode;
  skeletonItems?: number;
}) => {
  return (
    <div className={styles.list}>
      {isLoading ? (
        <LoadingSkeleton skeletonRender={skeletonRender} items={skeletonItems} />
      ) : (
        dataSource.map((dataItem) => (
          <div key={itemKey(dataItem)} className={cn(styles.item, styles.hoverableItem)}>
            {itemLink && <a href={itemLink(dataItem)} className={styles.itemLink} />}
            {renderItem(dataItem)}
          </div>
        ))
      )}
    </div>
  );
};

export default DataList;
