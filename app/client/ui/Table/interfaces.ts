import React from "react";

export type SortFunctionType<DataItem> = (itemA: DataItem, itemB: DataItem) => number;

export type SortOrder = "asc" | "desc";

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
  isHidden?: boolean,
  sorter?:
    | boolean
    | {
        compare: SortFunctionType<DataItem>,
        priority?: number,
      },
  supportAscSorting?: boolean,
  align?: "left" | "center" | "right",
  noWrap?: boolean,
}

export interface IComputedColumn<DataItem extends object = object> extends IColumn<DataItem> {
  _key: string,
}

export type ITableSorting = {
  sortBy?: string | null,
  sortOrder?: SortOrder | null,
  onSortChange?: (
    sortBy: string | null,
    sortOrder: SortOrder | null,
    supportMultipleSortOrders: boolean
  ) => void,
};
