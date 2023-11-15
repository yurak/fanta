import { useCallback, useState } from "react";
import { ILeaguesWithTournament } from "../interfaces";

export const useSearch = () => {
  const [search, setSearch] = useState("");

  const filterBySearch = useCallback(
    (leagues: ILeaguesWithTournament[]) => {
      if (!search) {
        return leagues;
      }

      const searchInLowerCase = search.toLowerCase();

      return leagues.filter((league) => league.name.toLowerCase().includes(searchInLowerCase));
    },
    [search]
  );

  return {
    filterBySearch,
    search,
    setSearch,
  };
};
