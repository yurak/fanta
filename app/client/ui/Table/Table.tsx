import React, { useMemo, useState } from "react";
import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import EmptyState from "../EmptyState";
import SortDownIcon from "../../assets/icons/sortDown.svg";
import styles from "./Table.module.scss";

export interface IColumn<DataItem extends {} = {}> {
  title?: string;
  dataKey: string;
  key?: string;
  render?: (item: DataItem, rowIndex: number) => React.ReactNode;
  skeleton?: React.ReactNode | ((rowIndex: number) => React.ReactNode);
  className?: string;
  dataClassName?: string | ((item: DataItem | null, rowIndex: number) => string);
  sorter?: (itemA: DataItem, itemB: DataItem) => number;
  align?: "left" | "center" | "right";
  noWrap?: boolean;
}

const getColumnKey = (column: IColumn) => column.key ?? column.dataKey;

const LoadingSkeleton = ({ columns, items }: { columns: IColumn[]; items: number }) => {
  return Array.from({ length: items }).map((_, rowIndex) => (
    <div key={rowIndex} className={cn(styles.row, styles.dataRow)}>
      {columns.map((column) => {
        const dataClassName =
          typeof column.dataClassName === "function"
            ? column.dataClassName(null, rowIndex)
            : column.dataClassName;

        return (
          <div
            key={getColumnKey(column)}
            className={cn(styles.column, styles.dataColumn, column.className, dataClassName, {
              [styles.right]: column.align === "right",
              [styles.center]: column.align === "center",
              [styles.noWrap]: column.noWrap,
            })}
          >
            {typeof column.skeleton === "function"
              ? column.skeleton(rowIndex)
              : column.skeleton ?? <Skeleton />}
          </div>
        );
      })}
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
  const [sortColumnKey, setSortColumnKey] = useState<null | string>(null);

  const getRowKey = (item: DataItem) => {
    if (typeof rowKey === "function") {
      return rowKey(item);
    }

    return item[rowKey ?? "id"];
  };

  const renderCellData = (item: DataItem, column: IColumn<DataItem>, rowIndex: number) => {
    return column.render?.(item, rowIndex) ?? item[column.dataKey];
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

  const onSort = (columnKey: string) => {
    setSortColumnKey(columnKey);
  };

  const sorterFunction = useMemo(() => {
    if (!sortColumnKey) {
      return null;
    }

    const sortedColumn = computedColumns.find((column) => sortColumnKey === column._key);

    if (!sortedColumn) {
      return null;
    }

    return sortedColumn.sorter;
  }, [computedColumns, sortColumnKey]);

  const sortedDataSource = useMemo(() => {
    if (!sorterFunction) {
      return dataSource;
    }

    return [...dataSource].sort(sorterFunction);
  }, [dataSource, sorterFunction]);

  return (
    <div className={styles.table}>
      <div className={cn(styles.header, styles.row)}>
        {computedColumns.map((column) => (
          <div
            key={column._key}
            className={cn(styles.column, styles.headerColumn, column.className, {
              [styles.withoutTitle]: !column.title,
              [styles.withSort]: !!column.sorter,
              [styles.isSorter]: column._key === sortColumnKey,
            })}
            onClick={() => {
              if (column.sorter) {
                onSort(column._key);
              }
            }}
          >
            {column.title}
            {column.sorter && (
              <span className={cn(styles.sortIcon)}>
                <SortDownIcon />
              </span>
            )}
          </div>
        ))}
      </div>
      {isLoading ? (
        <LoadingSkeleton columns={columns} items={skeletonItems} />
      ) : (
        <>
          {sortedDataSource.length > 0 ? (
            sortedDataSource.map((dataItem, rowIndex) => (
              <div
                key={getRowKey(dataItem)}
                className={cn(styles.row, styles.dataRow, styles.hoverableRow)}
              >
                {rowLink && <a href={rowLink(dataItem)} className={styles.rowLink} />}
                {computedColumns.map((column) => {
                  const dataClassName =
                    typeof column.dataClassName === "function"
                      ? column.dataClassName(dataItem, rowIndex)
                      : column.dataClassName;

                  return (
                    <div
                      key={column._key}
                      className={cn(
                        styles.column,
                        styles.dataColumn,
                        column.className,
                        dataClassName,
                        {
                          [styles.right]: column.align === "right",
                          [styles.center]: column.align === "center",
                          [styles.noWrap]: column.noWrap,
                        }
                      )}
                    >
                      {renderCellData(dataItem, column, rowIndex)}
                    </div>
                  );
                })}
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
