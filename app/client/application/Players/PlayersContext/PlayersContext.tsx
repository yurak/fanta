import { createContext, useContext, useState } from "react";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { IFilter } from "../PlayersFilterContext/interfaces";

const defaultSearch = "martinez";

const defaultFilter: IFilter = {
  position: [],
  totalScore: [PlayersFilterConstants.TOTAL_SCORE_MIN, PlayersFilterConstants.TOTAL_SCORE_MAX],
  baseScore: [PlayersFilterConstants.BASE_SCORE_MIN, PlayersFilterConstants.BASE_SCORE_MAX],
  appearances: [PlayersFilterConstants.APPEARANCES_MIN, PlayersFilterConstants.APPEARANCES_MAX],
  price: [PlayersFilterConstants.PRICE_MIN, PlayersFilterConstants.PRICE_MAX],
};

const usePlayers = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [search, setSearch] = useHistorySearch(defaultSearch);
  const { sortBy, sortOrder, onSortChange } = useHistorySort();

  const [filter, setFilter] = useState<IFilter>(defaultFilter);

  const clearFilter = () => {
    setFilter(defaultFilter);
  };

  const clearAllFilter = () => {
    setSearch(defaultSearch);
    clearFilter();
  };

  const openSidebar = () => setIsSidebarOpen(true);
  const closeSidebar = () => setIsSidebarOpen(false);

  return {
    filter,
    setFilter,
    clearFilter,
    clearAllFilter,
    search,
    setSearch,
    defaultSearch,
    sortBy,
    sortOrder,
    onSortChange,
    isSidebarOpen,
    openSidebar,
    closeSidebar,
  };
};

const PlayersContext = createContext<null | ReturnType<typeof usePlayers>>(null);

export const usePlayersContext = () => {
  const context = useContext(PlayersContext);

  if (!context) {
    throw new Error("usePlayersContext must be used within a PlayersContext");
  }

  return context;
};

const PlayersContextProvider = ({ children }: { children: React.ReactNode }) => {
  return <PlayersContext.Provider value={usePlayers()}>{children}</PlayersContext.Provider>;
};

export default PlayersContextProvider;
