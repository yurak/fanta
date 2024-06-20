import { createContext, useContext, useMemo, useState } from "react";
import { SortOrder, useHistorySort } from "@/hooks/useHistorySort";

const sortOptions: Array<{ sortOrder: SortOrder, sortBy: string, label: string }> = [
  {
    sortOrder: "desc",
    sortBy: "name",
    label: "Name (A to Z)",
  },
  {
    sortOrder: "asc",
    sortBy: "name",
    label: "Name (Z to A)",
  },
  {
    sortOrder: "asc",
    sortBy: "position",
    label: "Position (GK to ST)",
  },
  {
    sortOrder: "desc",
    sortBy: "position",
    label: "Position (ST to GK)",
  },
  {
    sortOrder: "desc",
    sortBy: "average_price",
    label: "Average price (Low to High)",
  },
  {
    sortOrder: "asc",
    sortBy: "average_price",
    label: "Average price (High to Low)",
  },
  {
    sortOrder: "desc",
    sortBy: "appearances",
    label: "Appearances (Low to High)",
  },
  {
    sortOrder: "asc",
    sortBy: "appearances",
    label: "Appearances (High to Low)",
  },
  {
    sortOrder: "desc",
    sortBy: "base_score",
    label: "Base score (Low to High)",
  },
  {
    sortOrder: "asc",
    sortBy: "base_score",
    label: "Base score (High to Low)",
  },
  {
    sortOrder: "desc",
    sortBy: "total_score",
    label: "Total score (Low to High)",
  },
  {
    sortOrder: "asc",
    sortBy: "total_score",
    label: "Total score (High to Low)",
  },
];

const usePlayersSort = () => {
  const { sortBy, sortOrder, onSortChange } = useHistorySort();

  const [value, setValue] = useState(sortBy && sortOrder ? { sortBy, sortOrder } : null);

  const selectedSort = useMemo(() => {
    return sortOptions.find(
      (option) => option.sortBy === value?.sortBy && option.sortOrder === value.sortOrder
    );
  }, [value]);

  const applySort = () => {
    onSortChange(value?.sortBy ?? null, value?.sortOrder ?? null);
  };

  return {
    selectedSort,
    sortOptions,
    value,
    setValue,
    applySort,
  };
};

const PlayersSortContext = createContext<null | ReturnType<typeof usePlayersSort>>(null);

export const usePlayersSortContext = () => {
  const context = useContext(PlayersSortContext);

  if (!context) {
    throw new Error("usePlayersSortContext must be used within a PlayersSortContext");
  }

  return context;
};

const PlayersSortContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <PlayersSortContext.Provider value={usePlayersSort()}>{children}</PlayersSortContext.Provider>
  );
};

export default PlayersSortContextProvider;
