import React from "react";
import cn from "classnames";
import styles from "./Table.module.scss";
import Skeleton from "react-loading-skeleton";

export interface IColumn<DataItem extends {} = {}> {
  title?: string;
  dataKey: string;
  key?: string;
  render?: (item: DataItem) => React.ReactNode;
  headColSpan?: number;
  width?: number | string;
  align?: "left" | "right";
  noWrap?: boolean;
  className?: string;
}

const getColumnKey = (column: IColumn) => column.key ?? column.dataKey;

const LoadingSkeleton = ({ columns, items }: { columns: IColumn[]; items: number }) => {
  return Array.from({ length: items }).map((_, index) => (
    <tr key={index.toString()} className={styles.tr}>
      {columns.map((column) => (
        <td
          key={getColumnKey(column)}
          className={cn(styles.td, column.className, {
            [styles.right]: column.align === "right",
            [styles.noWrap]: column.noWrap,
          })}
        >
          <span>
            <Skeleton />
          </span>
        </td>
      ))}
    </tr>
  ));
};

const Table = <DataItem extends {} = {}>({
  columns,
  dataSource,
  rowKey,
  rowLink,
  isLoading,
  skeletonItems = 6,
}: {
  columns: IColumn<DataItem>[];
  dataSource: DataItem[];
  rowKey?: string | ((item: DataItem) => string | number);
  rowLink?: (item: DataItem) => string;
  isLoading?: boolean;
  skeletonItems?: number;
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

  return (
    <table className={styles.table}>
      <colgroup>
        {columns.map((column) => (
          <col key={getColumnKey(column)} style={{ width: column.width }} />
        ))}
      </colgroup>
      <thead className={styles.thead}>
        <tr>
          {columns
            .filter((column) => column.headColSpan !== 0)
            .map((column) => (
              <th
                key={getColumnKey(column)}
                className={styles.th}
                {...(column.headColSpan && { colSpan: column.headColSpan })}
              >
                {column.title && <span>{column.title}</span>}
              </th>
            ))}
        </tr>
      </thead>
      <tbody>
        {isLoading ? (
          <LoadingSkeleton columns={columns} items={skeletonItems} />
        ) : (
          dataSource.map((dataItem) => (
            <tr key={getRowKey(dataItem)} className={cn(styles.tr, styles.hoverableTr)}>
              {columns.map((column, index) => (
                <td
                  key={getColumnKey(column)}
                  className={cn(styles.td, column.className, {
                    [styles.right]: column.align === "right",
                    [styles.noWrap]: column.noWrap,
                  })}
                >
                  {index === 0 && rowLink && (
                    <a href={rowLink(dataItem)} className={styles.rowLink} />
                  )}
                  <span>{renderCellData(dataItem, column)}</span>
                </td>
              ))}
            </tr>
          ))
        )}
      </tbody>
    </table>
  );
};

export default Table;
