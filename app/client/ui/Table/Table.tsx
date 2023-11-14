import React from "react";
import cn from "classnames";
import styles from "./Table.module.scss";

export interface IColumn<DataItem> {
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

const Table = <DataItem extends {}>({
  columns,
  dataSource,
  rowKey,
  rowLink,
}: {
  columns: IColumn<DataItem>[];
  dataSource: DataItem[];
  rowKey?: string | ((item: DataItem) => string | number);
  rowLink?: (item: DataItem) => string;
}) => {
  const getRowKey = (item: DataItem) => {
    if (typeof rowKey === "function") {
      return rowKey(item);
    }

    return item[rowKey ?? "id"];
  };

  const getColumnKey = (column: IColumn<DataItem>) => column.key ?? column.dataKey;

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
        {dataSource.map((dataItem) => (
          <tr key={getRowKey(dataItem)} className={styles.tr}>
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
        ))}
      </tbody>
    </table>
  );
};

export default Table;
