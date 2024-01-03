import React from "react";

export type SortFunctionType<DataItem> = (itemA: DataItem, itemB: DataItem) => number;

export interface IColumn<DataItem extends {} = {}> {
  title?: React.ReactNode;
  dataKey: string;
  key?: string;
  render?: (item: DataItem, rowIndex: number) => React.ReactNode;
  skeleton?: React.ReactNode | ((rowIndex: number) => React.ReactNode);
  className?: string;
  dataClassName?: string | ((item: DataItem | null, rowIndex: number) => string);
  sorter?: {
    compare: SortFunctionType<DataItem>;
    priority?: number;
  };
  align?: "left" | "center" | "right";
  noWrap?: boolean;
}

export interface IComputedColumn<DataItem extends {} = {}> extends IColumn<DataItem> {
  _key: string;
}
