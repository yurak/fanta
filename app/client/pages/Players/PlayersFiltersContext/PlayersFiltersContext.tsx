import { createContext, useContext, useMemo, useState } from "react";
import { ISeason } from "@/interfaces/Season";
import { useHistorySearch } from "@/hooks/useHistorySearch";
import { useHistorySort } from "@/hooks/useHistorySort";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";

const defaultSearch = "martinez";

const usePlayersFilters = () => {
  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);

  const [search, setSearch] = useHistorySearch(defaultSearch);
  const historySort = useHistorySort();

  const [position, setPosition] = useState<string[]>([]);

  const [totalScore, setTotalScore] = useState([
    PlayersFilterConstants.TOTAL_SCORE_MIN,
    PlayersFilterConstants.TOTAL_SCORE_MAX,
  ]);

  const [baseScore, setBaseScore] = useState([
    PlayersFilterConstants.BASE_SCORE_MIN,
    PlayersFilterConstants.BASE_SCORE_MAX,
  ]);

  const [appearances, setAppearances] = useState([
    PlayersFilterConstants.APPEARANCES_MIN,
    PlayersFilterConstants.APPEARANCES_MAX,
  ]);

  const [price, setPrice] = useState([
    PlayersFilterConstants.PRICE_MIN,
    PlayersFilterConstants.PRICE_MAX,
  ]);

  const filters = useMemo(
    () => ({ position, totalScore, baseScore, appearances, price }),
    [position, totalScore, baseScore, appearances, price]
  );

  const clearFilters = () => {
    setPosition([]);
    setTotalScore([PlayersFilterConstants.TOTAL_SCORE_MIN, PlayersFilterConstants.TOTAL_SCORE_MAX]);
    setBaseScore([PlayersFilterConstants.BASE_SCORE_MIN, PlayersFilterConstants.BASE_SCORE_MAX]);
    setAppearances([
      PlayersFilterConstants.APPEARANCES_MIN,
      PlayersFilterConstants.APPEARANCES_MAX,
    ]);
    setPrice([PlayersFilterConstants.PRICE_MIN, PlayersFilterConstants.PRICE_MAX]);
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
    totalScore,
    setTotalScore,
    baseScore,
    setBaseScore,
    appearances,
    setAppearances,
    price,
    setPrice,
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
