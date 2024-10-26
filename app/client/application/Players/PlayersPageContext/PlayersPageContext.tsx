import { createContext, useContext } from "react";

const usePlayersPage = ({
  isLeagueSpecificPlayersPage = false,
}: {
  isLeagueSpecificPlayersPage?: boolean,
}) => {
  return {
    isLeagueSpecificPlayersPage,
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

const PlayersPageContextProvider = ({
  children,
  ...rest
}: React.PropsWithChildren<{
  isLeagueSpecificPlayersPage?: boolean,
}>) => {
  return (
    <PlayersPageContext.Provider value={usePlayersPage(rest)}>
      {children}
    </PlayersPageContext.Provider>
  );
};

export default PlayersPageContextProvider;
