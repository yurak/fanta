import React from "react";

export type SortFunctionType<DataItem> = (itemA: DataItem, itemB: DataItem) => number;

export interface IColumn<DataItem extends object = object> {
  title?: React.ReactNode,
  dataKey: string,
  key?: string,
  render?: (item: DataItem, rowIndex: number) => React.ReactNode,
  skeleton?: React.ReactNode | ((rowIndex: number) => React.ReactNode),
  className?: string,
  dataClassName?: string | ((item: DataItem | null, rowIndex: number) => string),
  headClassName?: string,
  headEllipsis?: boolean,
  sorter?: {
    compare: SortFunctionType<DataItem>,
    priority?: number,
  },
  sticky?: boolean,
  align?: "left" | "center" | "right",
  noWrap?: boolean,
}

export interface IComputedColumn<DataItem extends object = object> extends IColumn<DataItem> {
  _key: string,
}

export type ITableSorting = {
  defaultSortColumn?: string | null,
  sortColumn?: string | null,
  setSortColumn?: (column: string | null) => void,
};
