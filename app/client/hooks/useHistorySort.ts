import { useMemo } from "react";
import { ITableSorting } from "@/ui/Table/interfaces";
import { useSearchParams } from "react-router-dom";

export const useHistorySort = (
  {
    defaultSortBy,
  }: {
    defaultSortBy: string | null,
  } = {
    defaultSortBy: null,
  }
): ITableSorting => {
  const [searchParams, setSearchParams] = useSearchParams();

  const sortBy = searchParams.get("sortBy") as ITableSorting["sortBy"];
  const sortOrder = searchParams.get("sortOrder") as ITableSorting["sortOrder"];

  const onSortChange: ITableSorting["onSortChange"] = (
    sortBy,
    sortOrder,
    supportMultipleSortOrders
  ) => {
    setSearchParams(
      (prev) => {
        if (sortBy) {
          prev.set("sortBy", sortBy.toString());
        } else {
          prev.delete("sortBy");
        }

        if (sortOrder && supportMultipleSortOrders) {
          prev.set("sortOrder", sortOrder.toString());
        } else {
          prev.delete("sortOrder");
        }

        return prev;
      },
      {
        replace: true,
      }
    );
  };

  return useMemo(
    () => ({
      sortBy: sortBy ?? defaultSortBy,
      sortOrder,
      onSortChange,
    }),
    [defaultSortBy, sortBy, onSortChange]
  );
};
