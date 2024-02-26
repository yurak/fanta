import { useMemo, useState } from "react";
import { IColumn, IComputedColumn, ITableSorting, SortFunctionType } from "./interfaces";

export const useSorting = <DataItem extends object = object>({
  sorting,
  columns,
  dataSource,
}: {
  sorting?: ITableSorting,
  columns: IComputedColumn<DataItem>[],
  dataSource: DataItem[],
}) => {
  /* Added state for cases where no need to control sort state outside of table component */
  const [_sortColumnKey, _setSortColumnKey]: [string | null, (column: string | null) => void] =
    useState<null | string>(null);

  const sortColumnKey = sorting?.sortColumn ?? _sortColumnKey;
  const setSortColumnKey = sorting?.setSortColumn ?? _setSortColumnKey;

  const onSort = (columnKey: string) => {
    const newSortColumnKey = sortColumnKey === columnKey ? null : columnKey;

    setSortColumnKey(newSortColumnKey);
  };

  const getSorterObject = (column: IColumn) => {
    if (typeof column.sorter === "object") {
      return column.sorter;
    }

    return null;
  };

  const columnSortFunction = useMemo(() => {
    if (!sortColumnKey) {
      return null;
    }

    const sortedColumn = columns.find((column) => sortColumnKey === column._key);

    if (!sortedColumn) {
      return null;
    }

    return getSorterObject(sortedColumn)?.compare ?? null;
  }, [columns, sortColumnKey]);

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
        result = sorter(itemA, itemB);
        i++;
      } while (result === 0 && sorterFunctions[i]);

      return result;
    });
  }, [dataSource, sorterFunctions]);

  return {
    sortColumnKey,
    sortedDataSource,
    onSort,
  };
};
