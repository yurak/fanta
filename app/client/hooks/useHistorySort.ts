import { useMemo } from "react";
import { useSearchParam } from "./useSearchParam";

export const useHistorySort = ({ defaultSortColumn }: { defaultSortColumn: string | null }) => {
  const [sortColumn, setSortColumn] = useSearchParam("order");

  return useMemo(
    () => ({
      sortColumn: sortColumn ?? defaultSortColumn,
      setSortColumn,
    }),
    [defaultSortColumn, sortColumn, setSortColumn]
  );
};
