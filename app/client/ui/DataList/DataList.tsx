import React from "react";
import cn from "classnames";
import Skeleton from "react-loading-skeleton";
import EmptyState from "@/ui/EmptyState";
import styles from "./DataList.module.scss";
import InfinityScrollDetector from "@/components/InfinityScrollDetector";

const LoadingSkeleton = ({
  skeletonRender = () => <Skeleton />,
  items = 5,
  itemClassName,
}: {
  skeletonRender?: () => React.ReactNode,
  items?: number,
  itemClassName?: string,
}) => {
  return Array.from({ length: items }).map((_, index) => (
    <div key={index} className={cn(styles.item, itemClassName)}>
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
  isLoadingMore,
  onLoadMore,
  skeletonItems,
  emptyStateComponent = <EmptyState title="No data" />,
}: {
  dataSource: DataItem[],
  renderItem: (item: DataItem) => React.ReactNode,
  itemKey: (item: DataItem) => string | number,
  itemLink?: (item: DataItem) => string,
  itemClassName?: string,
  isLoading?: boolean,
  skeletonRender?: () => React.ReactNode,
  isLoadingMore?: boolean,
  onLoadMore?: () => void,
  skeletonItems?: number,
  emptyStateComponent?: React.ReactNode,
}) => {
  return (
    <div className={styles.list}>
      {isLoading ? (
        <LoadingSkeleton
          skeletonRender={skeletonRender}
          items={skeletonItems}
          itemClassName={itemClassName}
        />
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
            <div className={styles.emptyState}>{emptyStateComponent}</div>
          )}
          {isLoadingMore && (
            <>
              <InfinityScrollDetector loadMore={() => onLoadMore?.()} />
              <LoadingSkeleton
                skeletonRender={skeletonRender}
                items={skeletonItems}
                itemClassName={itemClassName}
              />
            </>
          )}
        </>
      )}
    </div>
  );
};

export default DataList;
