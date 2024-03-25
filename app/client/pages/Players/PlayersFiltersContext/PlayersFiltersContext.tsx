import { createContext, useContext, useMemo, useState } from "react";
import { ISeason } from "@/interfaces/Season";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";

const defaultSearch = "martinez";

const usePlayersFilters = () => {
  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);

  const [search, setSearch] = useHistorySearch(defaultSearch);
  const historySort = useHistorySort();

  const [position, setPosition] = useState<string[]>([]);

  const filters = useMemo(() => ({ position }), [position]);

  const clearFilters = () => {
    setPosition([]);
  };

  return {
    filters,
    clearFilters,
    position,
    setPosition,
    selectedSeason,
    setSelectedSeason,
    search,
    setSearch,
    defaultSearch,
    historySort,
  };
};

const PlayersFiltersContext = createContext<null | ReturnType<typeof usePlayersFilters>>(null);

export const usePlayersFiltersContext = () => {
  const context = useContext(PlayersFiltersContext);

  if (!context) {
    throw new Error("usePlayersFiltersContext must be used within a PlayersFiltersContext");
  }

  return context;
};

const PlayersFiltersContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <PlayersFiltersContext.Provider value={usePlayersFilters()}>
      {children}
    </PlayersFiltersContext.Provider>
  );
};

export default PlayersFiltersContextProvider;
