import { useLeague } from "@/api/query/useLeague";
import { createContext, useContext } from "react";
import { usePlayersContext } from "../PlayersContext";

const usePlayersPage = () => {
  const {
    filterValues: { league: leagueId },
  } = usePlayersContext();

  const isLeagueSpecificPlayersPage = Boolean(leagueId);

  const {
    data: league,
    isLoading,
    isPending,
  } = useLeague(leagueId as number, isLeagueSpecificPlayersPage);

  return {
    isLeagueSpecificPlayersPage,
    isLeagueFetching: (isLoading || isPending) && isLeagueSpecificPlayersPage,
    league,
  };
};

const PlayersPageContext = createContext<null | ReturnType<typeof usePlayersPage>>(null);

export const usePlayersPageContext = () => {
  const context = useContext(PlayersPageContext);

  if (!context) {
    throw new Error("usePlayersPageContext must be used within a PlayersPageContext");
  }

  return context;
};

const PlayersPageContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <PlayersPageContext.Provider value={usePlayersPage()}>{children}</PlayersPageContext.Provider>
  );
};

export default PlayersPageContextProvider;
