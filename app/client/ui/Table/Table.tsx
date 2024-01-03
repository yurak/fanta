import { useMemo } from "react";
import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import EmptyState from "../EmptyState";
import SortDownIcon from "../../assets/icons/sortDown.svg";
import { IColumn, IComputedColumn } from "./interfaces";
import { useSorting } from "./useSorting";
import styles from "./Table.module.scss";

const LoadingSkeleton = ({ columns, items }: { columns: IComputedColumn[]; items: number }) => {
  return Array.from({ length: items }).map((_, rowIndex) => (
    <div key={rowIndex} className={cn(styles.row, styles.dataRow)}>
      {columns.map((column) => {
        const dataClassName =
          typeof column.dataClassName === "function"
            ? column.dataClassName(null, rowIndex)
            : column.dataClassName;

        return (
          <div
            key={column._key}
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
  tableClassName,
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
  tableClassName?: string;
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

  const renderCellData = (item: DataItem, column: IColumn<DataItem>, rowIndex: number) => {
    return column.render?.(item, rowIndex) ?? item[column.dataKey];
  };

  const computedColumns = useMemo<IComputedColumn<DataItem>[]>(
    () =>
      columns.map((column) => {
        return {
          ...column,
          _key: column.key ?? column.dataKey,
        };
      }),
    [columns]
  );

  const { onSort, sortColumnKey, sortedDataSource } = useSorting({
    columns: computedColumns,
    dataSource,
  });

  return (
    <div className={styles.tableWrapper}>
      <div className={cn(styles.table, tableClassName)}>
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
          <LoadingSkeleton columns={computedColumns} items={skeletonItems} />
        ) : (
          <>
            {sortedDataSource.length > 0 ? (
              sortedDataSource.map((dataItem, rowIndex) => (
                <div
                  key={getRowKey(dataItem)}
                  className={cn(styles.row, styles.dataRow, {
                    [styles.hoverableRow]: Boolean(rowLink),
                  })}
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
    </div>
  );
};

export default Table;
