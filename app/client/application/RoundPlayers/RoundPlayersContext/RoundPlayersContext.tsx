import { createContext, useContext, useMemo, useState } from "react";
import { useDebounceCallback, useDebounceValue } from "usehooks-ts";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";
import { useHistoryFilter } from "@/hooks/useHistoryFilter";
import { getObjectDiffKeys } from "@/helpers/getObjectDiff";
import { IRoundPlayerPayloadFilter } from "@/api/query/useRoundPlayers";
import { IPayloadSort } from "@/api/query/usePlayers";
import { IRoundPlayerFilter } from "../RoundPlayersFilterContext/interfaces";
import { defaultFilter, defaultSearch } from "../RoundPlayersFilterContext/constants";
import { filterToRequestFormat, sortToRequestFormat } from "../RoundPlayersFilterContext/helpers";
import { decodeFilter, encodeFilter } from "../RoundPlayersFilterContext/searchParamsHelpers";

const DEBOUNCE_DELAY = 1_000;

const useRoundPlayers = () => {
  const sorting = useHistorySort({ defaultSortBy: "result_score", defaultSortOrder: "desc" });

  const [search, setSearch] = useHistorySearch(defaultSearch);
  const [historyFilter, setHistoryFilter] = useHistoryFilter<IRoundPlayerFilter>(
    decodeFilter,
    encodeFilter
  );
  const [debounceSearch] = useDebounceValue(search, DEBOUNCE_DELAY);

  const [filterValues, _setFilterValues] = useState<IRoundPlayerFilter>(historyFilter);

  const filterCount = getObjectDiffKeys(defaultFilter, filterValues).length;

  const setFilterValues = (filter: IRoundPlayerFilter) => {
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

  const requestFilterPayload = useMemo<IRoundPlayerPayloadFilter>(
    () => filterToRequestFormat(filterValues, debounceSearch),
    [filterValues, debounceSearch]
  );

  const requestSortPayload = useMemo<IPayloadSort | undefined>(
    () => sortToRequestFormat(sorting.sortBy, sorting.sortOrder),
    [sorting.sortBy, sorting.sortOrder]
  );

  return {
    filterCount,
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
    sorting,
  };
};

const RoundPlayersContext = createContext<null | ReturnType<typeof useRoundPlayers>>(null);

export const useRoundPlayersContext = () => {
  const context = useContext(RoundPlayersContext);

  if (!context) {
    throw new Error("useRoundPlayersContext must be used within a RoundPlayersContext");
  }

  return context;
};

const RoundPlayersContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <RoundPlayersContext.Provider value={useRoundPlayers()}>{children}</RoundPlayersContext.Provider>
  );
};

export default RoundPlayersContextProvider;
