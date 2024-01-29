import { useMemo } from "react";
import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import TableBodyCell from "./TableBodyCell";
import TableHeaderCell from "./TableHeaderCell";
import EmptyState from "../EmptyState";
import { useSorting } from "./useSorting";
import { IColumn, IComputedColumn, ITableSorting } from "./interfaces";
import styles from "./Table.module.scss";

const LoadingSkeleton = ({ columns, items }: { columns: IComputedColumn[], items: number }) => {
  return Array.from({ length: items }).map((_, rowIndex) => (
    <div key={rowIndex} className={cn(styles.row, styles.dataRow)}>
      {columns.map((column) => {
        const dataClassName =
          typeof column.dataClassName === "function"
            ? column.dataClassName(null, rowIndex)
            : column.dataClassName;

        return (
          <TableBodyCell
            key={column._key}
            align={column.align}
            noWrap={column.noWrap}
            className={cn(column.className, dataClassName)}
          >
            {typeof column.skeleton === "function"
              ? column.skeleton(rowIndex)
              : column.skeleton ?? <Skeleton />}
          </TableBodyCell>
        );
      })}
    </div>
  ));
};

const Table = <DataItem extends object = object>({
  columns,
  dataSource,
  rowKey,
  rowLink,
  isLoading,
  skeletonItems = 6,
  tableClassName,
  sorting,
  emptyState = {
    title: "No data",
  },
}: {
  columns: IColumn<DataItem>[],
  dataSource: DataItem[],
  rowKey?: string | ((item: DataItem) => string | number),
  rowLink?: (item: DataItem) => string,
  isLoading?: boolean,
  skeletonItems?: number,
  tableClassName?: string,
  sorting?: ITableSorting,
  emptyState?: {
    title: string,
    description?: string,
  },
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
    sorting,
    columns: computedColumns,
    dataSource,
  });

  return (
    <div className={styles.tableWrapper}>
      <div className={cn(styles.table, tableClassName)}>
        <div className={cn(styles.header, styles.row)}>
          {computedColumns.map((column) => (
            <TableHeaderCell
              key={column._key}
              className={cn(column.className, column.headClassName)}
              title={column.title}
              withSort={!!column.sorter}
              isSorter={column._key === sortColumnKey}
              onSort={() => onSort(column._key)}
            />
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
                  {computedColumns.map((column) => {
                    const dataClassName =
                      typeof column.dataClassName === "function"
                        ? column.dataClassName(dataItem, rowIndex)
                        : column.dataClassName;

                    return (
                      <TableBodyCell
                        key={column._key}
                        align={column.align}
                        noWrap={column.noWrap}
                        sticky={column.sticky}
                        className={cn(column.className, dataClassName)}
                      >
                        {renderCellData(dataItem, column, rowIndex)}
                      </TableBodyCell>
                    );
                  })}
                  {rowLink && <a href={rowLink(dataItem)} className={styles.rowLink} />}
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
