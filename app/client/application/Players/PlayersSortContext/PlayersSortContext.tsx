import { createContext, useContext, useMemo, useState } from "react";
import { SortOrder, useHistorySort } from "@/hooks/useHistorySort";
import { useTranslation } from "react-i18next";

const usePlayersSort = () => {
  const { sortBy, sortOrder, onSortChange } = useHistorySort();

  const [value, setValue] = useState(sortBy && sortOrder ? { sortBy, sortOrder } : null);

  const { t } = useTranslation();

  const sortOptions = useMemo<Array<{ sortOrder: SortOrder, sortBy: string, label: string }>>(
    () => [
      {
        sortOrder: "desc",
        sortBy: "name",
        label: t("players.sorter.nameDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "name",
        label: t("players.sorter.nameAsc"),
      },
      {
        sortOrder: "desc",
        sortBy: "position",
        label: t("players.sorter.positionDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "position",
        label: t("players.sorter.positionAsc"),
      },
      {
        sortOrder: "desc",
        sortBy: "average_price",
        label: t("players.sorter.avaragePriceDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "average_price",
        label: t("players.sorter.avaragePriceAsc"),
      },
      {
        sortOrder: "desc",
        sortBy: "appearances",
        label: t("players.sorter.appearancesDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "appearances",
        label: t("players.sorter.appearancesAsc"),
      },
      {
        sortOrder: "desc",
        sortBy: "base_score",
        label: t("players.sorter.baseScoreDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "base_score",
        label: t("players.sorter.baseScoreAsc"),
      },
      {
        sortOrder: "desc",
        sortBy: "total_score",
        label: t("players.sorter.totalScoreDesc"),
      },
      {
        sortOrder: "asc",
        sortBy: "total_score",
        label: t("players.sorter.totalScoreAsc"),
      },
    ],
    [t]
  );

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
