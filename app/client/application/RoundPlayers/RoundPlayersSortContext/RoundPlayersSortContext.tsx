import { createContext, useContext, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { SortOrder } from "@/hooks/useHistorySort";
import { useRoundPlayersContext } from "../RoundPlayersContext";
import { useRoundPlayersPageConfigurationContext } from "../RoundPlayersPageConfigurationContext";

export interface ISortValue {
  sortBy: string,
  sortOrder: SortOrder,
}

export interface ISortOption extends ISortValue {
  label: string,
}

const useRoundPlayersSort = () => {
  const {
    sorting: { onSortChange, sortBy, sortOrder },
  } = useRoundPlayersContext();
  const { fanta, deadlined } = useRoundPlayersPageConfigurationContext();

  const { t } = useTranslation();

  const sortOptions = useMemo<ISortOption[]>(() => {
    const tr = (key: string) => t(`round_players_page.sorter.${key}`);

    return [
      { sortBy: "result_score", sortOrder: "desc", label: tr("result_score_desc") },
      { sortBy: "result_score", sortOrder: "asc", label: tr("result_score_asc") },
      { sortBy: "base_score", sortOrder: "desc", label: tr("base_score_desc") },
      { sortBy: "base_score", sortOrder: "asc", label: tr("base_score_asc") },
      // Appearance sorting is only meaningful for deadlined fanta rounds.
      ...(fanta && deadlined
        ? ([
            { sortBy: "appearances", sortOrder: "desc", label: tr("appearances_desc") },
            { sortBy: "appearances", sortOrder: "asc", label: tr("appearances_asc") },
            { sortBy: "main_squad", sortOrder: "desc", label: tr("main_squad_desc") },
            { sortBy: "main_squad", sortOrder: "asc", label: tr("main_squad_asc") },
          ] as ISortOption[])
        : []),
      { sortBy: "name", sortOrder: "asc", label: tr("name_asc") },
      { sortBy: "name", sortOrder: "desc", label: tr("name_desc") },
      { sortBy: "club", sortOrder: "asc", label: tr("club_asc") },
      { sortBy: "club", sortOrder: "desc", label: tr("club_desc") },
    ];
  }, [t, fanta, deadlined]);

  const selectedSort = useMemo(
    () => sortOptions.find((option) => option.sortBy === sortBy && option.sortOrder === sortOrder),
    [sortOptions, sortBy, sortOrder]
  );

  const applySort = (value: ISortValue | null) => {
    onSortChange(value?.sortBy ?? null, value?.sortOrder ?? null);
  };

  return {
    sortOptions,
    selectedSort,
    applySort,
  };
};

const RoundPlayersSortContext = createContext<null | ReturnType<typeof useRoundPlayersSort>>(null);

export const useRoundPlayersSortContext = () => {
  const context = useContext(RoundPlayersSortContext);

  if (!context) {
    throw new Error("useRoundPlayersSortContext must be used within a RoundPlayersSortContext");
  }

  return context;
};

const RoundPlayersSortContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <RoundPlayersSortContext.Provider value={useRoundPlayersSort()}>
      {children}
    </RoundPlayersSortContext.Provider>
  );
};

export default RoundPlayersSortContextProvider;
