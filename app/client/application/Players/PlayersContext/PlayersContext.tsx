import { createContext, useContext, useMemo, useState } from "react";
import { useDebounceCallback, useDebounceValue } from "usehooks-ts";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { IFilter } from "../PlayersFilterContext/interfaces";
import { IPayloadFilter, IPayloadSort } from "@/api/query/usePlayers";

const defaultSearch = "martinez";
const defaultFilter: IFilter = {
  position: [],
  totalScore: {
    min: PlayersFilterConstants.TOTAL_SCORE_MIN,
    max: PlayersFilterConstants.TOTAL_SCORE_MAX,
  },
  baseScore: {
    min: PlayersFilterConstants.BASE_SCORE_MIN,
    max: PlayersFilterConstants.BASE_SCORE_MAX,
  },
  appearances: {
    min: PlayersFilterConstants.APPEARANCES_MIN,
    max: PlayersFilterConstants.APPEARANCES_MAX,
  },
  price: {
    min: PlayersFilterConstants.PRICE_MIN,
    max: PlayersFilterConstants.PRICE_MAX,
  },
};

const DEBOUNCE_DELAY = 500;

const usePlayers = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const { sortBy, sortOrder, onSortChange } = useHistorySort();

  const [search, setSearch] = useHistorySearch(defaultSearch);
  const [debounceSearch] = useDebounceValue(search, DEBOUNCE_DELAY);

  const [filterValues, setFilterValues] = useState<IFilter>(defaultFilter);
  const setFilterValuesWithDebounce = useDebounceCallback(setFilterValues, DEBOUNCE_DELAY);

  const clearFilter = () => {
    setFilterValues(defaultFilter);
  };

  const clearAllFilter = () => {
    setSearch(defaultSearch);
    clearFilter();
  };

  const openSidebar = () => setIsSidebarOpen(true);
  const closeSidebar = () => setIsSidebarOpen(false);

  const requestFilterPayload = useMemo<IPayloadFilter>(
    () => ({
      name: debounceSearch,
      position: filterValues.position,
      base_score: filterValues.baseScore,
      total_score: filterValues.totalScore,
      app: filterValues.appearances,
      price: filterValues.price,
    }),
    [debounceSearch, filterValues]
  );

  const requestSortPayload = useMemo<IPayloadSort | undefined>(() => {
    if (sortBy && sortOrder) {
      return {
        field: sortBy,
        direction: sortOrder,
      };
    }

    return undefined;
  }, [sortBy, sortOrder]);

  return {
    requestFilterPayload,
    requestSortPayload,
    filterValues,
    setFilterValues,
    setFilterValuesWithDebounce,
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
