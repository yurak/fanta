import { useMemo } from "react";
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
  }: {
    defaultSortBy: string | null,
  } = {
    defaultSortBy: null,
  }
): ISorting => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

  const sortBy = searchParams.get("sortBy") as ISorting["sortBy"];
  const sortOrder = searchParams.get("sortOrder") as ISorting["sortOrder"];

  const onSortChange: ISorting["onSortChange"] = (
    sortBy,
    sortOrder,
    supportMultipleSortOrders = true
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
