import { createContext, useContext } from "react";

const usePlayersPageConfiguration = ({
  isLeagueSpecificPlayersPage = false,
}: {
  isLeagueSpecificPlayersPage?: boolean,
}) => {
  return {
    isLeagueSpecificPlayersPage,
  };
};

const PlayersPageConfigurationContext = createContext<null | ReturnType<
  typeof usePlayersPageConfiguration
>>(null);

export const usePlayersPageConfigurationContext = () => {
  const context = useContext(PlayersPageConfigurationContext);

  if (!context) {
    throw new Error(
      "usePlayersPageConfigurationContext must be used within a PlayersPageConfigurationContext"
    );
  }

  return context;
};

const PlayersPageConfigurationContextProvider = ({
  children,
  ...rest
}: React.PropsWithChildren<{
  isLeagueSpecificPlayersPage?: boolean,
}>) => {
  return (
    <PlayersPageConfigurationContext.Provider value={usePlayersPageConfiguration(rest)}>
      {children}
    </PlayersPageConfigurationContext.Provider>
  );
};

export default PlayersPageConfigurationContextProvider;
