import { createContext, useContext } from "react";

interface IProps {
  leagueId?: number,
}

const usePlayersPageConfiguration = ({ leagueId }: IProps) => {
  const isLeagueSpecificPlayersPage = !!leagueId;

  return {
    isLeagueSpecificPlayersPage,
    leagueId,
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
}: React.PropsWithChildren<IProps>) => {
  return (
    <PlayersPageConfigurationContext.Provider value={usePlayersPageConfiguration(rest)}>
      {children}
    </PlayersPageConfigurationContext.Provider>
  );
};

export default PlayersPageConfigurationContextProvider;
