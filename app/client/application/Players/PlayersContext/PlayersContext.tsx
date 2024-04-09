import { createContext, useContext, useMemo, useState } from "react";
import { useDebounceCallback, useDebounceValue } from "usehooks-ts";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";
import { IFilter } from "../PlayersFilterContext/interfaces";
import { IPayloadFilter, IPayloadSort } from "@/api/query/usePlayers";
import { useHistoryFilter } from "@/hooks/useHistoryFilter";
import { defaultFilter, defaultSearch } from "../PlayersFilterContext/constants";
import { filterToRequestFormat, sortToRequestFormat } from "../PlayersFilterContext/helpers";
import { decodeFilter, encodeFilter } from '../PlayersFilterContext/searchParamsHelpers';

const DEBOUNCE_DELAY = 500;

const usePlayers = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const { sortBy, sortOrder, onSortChange } = useHistorySort();

  const [search, setSearch] = useHistorySearch(defaultSearch);
  const [historyFilter, setHistoryFilter] = useHistoryFilter<IFilter>(decodeFilter, encodeFilter);
  const [debounceSearch] = useDebounceValue(search, DEBOUNCE_DELAY);

  const [filterValues, _setFilterValues] = useState<IFilter>(historyFilter);

  const setFilterValues = (filter: IFilter) => {
    _setFilterValues(filter);
    setHistoryFilter(filter);
  };

  const clearFilter = () => {
    setFilterValues(defaultFilter);
  };

  const setFilterValuesWithDebounce = useDebounceCallback(setFilterValues, DEBOUNCE_DELAY);

  const clearAllFilter = () => {
    setSearch(defaultSearch);
    clearFilter();
  };

  const openSidebar = () => setIsSidebarOpen(true);
  const closeSidebar = () => setIsSidebarOpen(false);

  const requestFilterPayload = useMemo<IPayloadFilter>(
    () => filterToRequestFormat(filterValues, debounceSearch),
    [filterValues, debounceSearch]
  );

  const requestSortPayload = useMemo<IPayloadSort | undefined>(
    () => sortToRequestFormat(sortBy, sortOrder),
    [sortBy, sortOrder]
  );

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
