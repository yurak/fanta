import { useMemo } from "react";
import { useSearchParam } from "./useSearchParam";

export const useHistorySort = () => {
  const [sortColumn, setSortColumn] = useSearchParam("order");

  return useMemo(
    () => ({
      sortColumn,
      setSortColumn,
    }),
    [sortColumn, setSortColumn]
  );
};
