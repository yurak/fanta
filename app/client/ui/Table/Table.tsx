import React, { useMemo } from "react";
import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import EmptyState from "../EmptyState";
import styles from "./Table.module.scss";

export interface IColumn<DataItem extends {} = {}> {
  title?: string;
  dataKey: string;
  key?: string;
  render?: (item: DataItem) => React.ReactNode;
  skeleton?: React.ReactNode;
  className?: string;
  dataClassName?: string;
  align?: "left" | "right";
  noWrap?: boolean;
}

const getColumnKey = (column: IColumn) => column.key ?? column.dataKey;

const LoadingSkeleton = ({ columns, items }: { columns: IColumn[]; items: number }) => {
  return Array.from({ length: items }).map((_, index) => (
    <div key={index} className={cn(styles.row, styles.dataRow)}>
      {columns.map((column) => (
        <div
          key={getColumnKey(column)}
          className={cn(styles.column, styles.dataColumn, column.className, column.dataClassName, {
            [styles.right]: column.align === "right",
            [styles.noWrap]: column.noWrap,
          })}
        >
          {column.skeleton ?? <Skeleton />}
        </div>
      ))}
    </div>
  ));
};

const Table = <DataItem extends {} = {}>({
  columns,
  dataSource,
  rowKey,
  rowLink,
  isLoading,
  skeletonItems = 6,
  emptyState = {
    title: "No data",
  },
}: {
  columns: IColumn<DataItem>[];
  dataSource: DataItem[];
  rowKey?: string | ((item: DataItem) => string | number);
  rowLink?: (item: DataItem) => string;
  isLoading?: boolean;
  skeletonItems?: number;
  emptyState?: {
    title: string;
    description?: string;
  };
}) => {
  const getRowKey = (item: DataItem) => {
    if (typeof rowKey === "function") {
      return rowKey(item);
    }

    return item[rowKey ?? "id"];
  };

  const renderCellData = (item: DataItem, column: IColumn<DataItem>) => {
    return column.render?.(item) ?? item[column.dataKey];
  };

  const computedColumns = useMemo(
    () =>
      columns.map((column) => {
        return {
          ...column,
          _key: getColumnKey(column),
        };
      }),
    [columns]
  );

  return (
    <div className={styles.table}>
      <div className={cn(styles.header, styles.row)}>
        {computedColumns.map((column) => (
          <div
            key={column._key}
            className={cn(styles.column, styles.headerColumn, column.className)}
          >
            {column.title}
          </div>
        ))}
      </div>
      {isLoading ? (
        <LoadingSkeleton columns={columns} items={skeletonItems} />
      ) : (
        <>
          {dataSource.length > 0 ? (
            dataSource.map((dataItem) => (
              <div
                key={getRowKey(dataItem)}
                className={cn(styles.row, styles.dataRow, styles.hoverableRow)}
              >
                {rowLink && <a href={rowLink(dataItem)} className={styles.rowLink} />}
                {computedColumns.map((column) => (
                  <div
                    key={column._key}
                    className={cn(
                      styles.column,
                      styles.dataColumn,
                      column.className,
                      column.dataClassName,
                      {
                        [styles.right]: column.align === "right",
                        [styles.noWrap]: column.noWrap,
                      }
                    )}
                  >
                    {renderCellData(dataItem, column)}
                  </div>
                ))}
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

export default Table;
