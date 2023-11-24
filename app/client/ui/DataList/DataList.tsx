import React from "react";
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
  isLoading,
  skeletonRender,
  skeletonItems,
}: {
  dataSource: DataItem[];
  renderItem: (item: DataItem) => React.ReactNode;
  itemKey: (item: DataItem) => string | number;
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
          <div key={itemKey(dataItem)} className={styles.item}>
            {renderItem(dataItem)}
          </div>
        ))
      )}
    </div>
  );
};

export default DataList;
