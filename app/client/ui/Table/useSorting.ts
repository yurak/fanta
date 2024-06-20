import { useMemo, useState } from "react";
import { IColumn, IComputedColumn, SortFunctionType } from "./interfaces";
import { ISorting, SortOrder } from "@/hooks/useHistorySort";

export const useSorting = <DataItem extends object = object>({
  sorting,
  columns,
  dataSource,
}: {
  sorting?: Partial<ISorting>,
  columns: IComputedColumn<DataItem>[],
  dataSource: DataItem[],
}) => {
  /* Added state for cases where no need to control sort state outside of table component */
  const [_sortBy, _setSortBy] = useState<null | string>(null);
  const [_sortOrder, _setSortOrder] = useState<SortOrder | null>(null);
  const _onSortChange = (sortBy: string | null, sortOrder: SortOrder | null) => {
    _setSortBy(sortBy);
    _setSortOrder(sortOrder);
  };

  const sortBy = sorting?.sortBy ?? _sortBy;
  const sortOrder = sorting?.sortOrder ?? _sortOrder;
  const onSortChange = sorting?.onSortChange ?? _onSortChange;

  const onSort = (column: IComputedColumn<DataItem>) => {
    const supportAscSorting = column.supportAscSorting ?? false;
    const sortOrders: ["desc", "asc"] | ["desc"] = supportAscSorting ? ["desc", "asc"] : ["desc"];
    const supportedSortOrders = [null, ...sortOrders];

    if (sortBy !== column._key) {
      onSortChange(column._key, sortOrders[0], supportAscSorting);

      return;
    }

    const currentSortIndex = supportedSortOrders.findIndex((o) => o === sortOrder);
    const nextSortOrder =
      supportedSortOrders[currentSortIndex + (1 % supportedSortOrders.length)] ?? null;

    if (!nextSortOrder) {
      onSortChange(null, null, supportAscSorting);
    } else {
      onSortChange(column._key, nextSortOrder, supportAscSorting);
    }
  };

  const getSorterObject = (column: IColumn) => {
    if (typeof column.sorter === "object") {
      return column.sorter;
    }

    return null;
  };

  const columnSortFunction = useMemo(() => {
    if (!sortBy) {
      return null;
    }

    const sortedColumn = columns.find((column) => sortBy === column._key);

    if (!sortedColumn) {
      return null;
    }

    return getSorterObject(sortedColumn)?.compare ?? null;
  }, [columns, sortBy]);

  const prioritySortingFunctions = useMemo(() => {
    return columns
      .filter((column) => getSorterObject(column)?.priority ?? false)
      .sort((columnA, columnB) => {
        return (
          (getSorterObject(columnA)?.priority ?? Number.POSITIVE_INFINITY) -
          (getSorterObject(columnB)?.priority ?? Number.POSITIVE_INFINITY)
        );
      })
      .map((column) => getSorterObject(column)?.compare) as SortFunctionType<DataItem>[];
  }, [columns]);

  const sorterFunctions = useMemo(() => {
    if (!columnSortFunction) {
      return [];
    }

    return [
      columnSortFunction,
      ...prioritySortingFunctions.filter((fn) => fn !== columnSortFunction),
    ];
  }, [prioritySortingFunctions, columnSortFunction]);

  const sortedDataSource = useMemo(() => {
    if (!sorterFunctions.length) {
      return dataSource;
    }

    return [...dataSource].sort((itemA, itemB) => {
      let result: number | undefined;
      let i = 0;

      do {
        const sorter = sorterFunctions[i] as SortFunctionType<DataItem>;
        result = sortOrder === "asc" ? sorter(itemB, itemA) : sorter(itemA, itemB);
        i++;
      } while (result === 0 && sorterFunctions[i]);

      return result;
    });
  }, [dataSource, sorterFunctions, sortOrder]);

  return {
    sortBy,
    sortedDataSource,
    sortOrder,
    onSort,
  };
};
