import { useMemo, useState } from "react";
import { useSearchParamsContext } from "@/application/SearchParamsContext";

export type SortOrder = "asc" | "desc";

export type ISorting = {
  sortBy: string | null,
  sortOrder: SortOrder | null,
  onSortChange: (
    sortBy: string | null,
    sortOrder: SortOrder | null,
    supportMultipleSortOrders?: boolean
  ) => void,
};

export const useHistorySort = (
  {
    defaultSortBy,
    defaultSortOrder,
  }: {
    defaultSortBy?: string | null,
    defaultSortOrder?: SortOrder | null,
  } = {
    defaultSortBy: null,
    defaultSortOrder: null,
  }
): ISorting => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

  const [sortBy, _setSortBy] = useState(searchParams.get("sortBy") ?? null);
  const [sortOrder, _setSortOrder] = useState(searchParams.get("sortOrder") as SortOrder | null);

  const onSortChange: ISorting["onSortChange"] = (
    sortBy,
    sortOrder,
    supportMultipleSortOrders = true
  ) => {
    setSearchParams(
      (prev) => {
        if (sortBy) {
          _setSortBy(sortBy);
          prev.set("sortBy", sortBy);
        } else {
          _setSortBy(null);
          prev.delete("sortBy");
        }

        if (sortOrder && supportMultipleSortOrders) {
          prev.set("sortOrder", sortOrder);
          _setSortOrder(sortOrder);
        } else {
          prev.delete("sortOrder");
          _setSortOrder(null);
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
      ...(!sortBy && !sortOrder
        ? {
            sortBy: defaultSortBy ?? null,
            sortOrder: defaultSortOrder ?? null,
          }
        : {
            sortBy,
            sortOrder,
          }),
      onSortChange,
    }),
    [defaultSortBy, sortBy, onSortChange]
  );
};
