import { createContext, useContext } from "react";
import { IRoundClub, IRoundLeague, IRoundPlayersMeta } from "@/interfaces/RoundPlayer";

interface IProps {
  roundId: number,
  meta?: IRoundPlayersMeta,
}

const useRoundPlayersPageConfiguration = ({ roundId, meta }: IProps) => {
  return {
    roundId,
    national: meta?.national ?? false,
    fanta: meta?.fanta ?? false,
    leagues: (meta?.leagues ?? []) as IRoundLeague[],
    clubs: (meta?.clubs ?? []) as IRoundClub[],
  };
};

const RoundPlayersPageConfigurationContext = createContext<null | ReturnType<
  typeof useRoundPlayersPageConfiguration
>>(null);

export const useRoundPlayersPageConfigurationContext = () => {
  const context = useContext(RoundPlayersPageConfigurationContext);

  if (!context) {
    throw new Error(
      "useRoundPlayersPageConfigurationContext must be used within a RoundPlayersPageConfigurationContext"
    );
  }

  return context;
};

const RoundPlayersPageConfigurationContextProvider = ({
  children,
  ...rest
}: React.PropsWithChildren<IProps>) => {
  return (
    <RoundPlayersPageConfigurationContext.Provider value={useRoundPlayersPageConfiguration(rest)}>
      {children}
    </RoundPlayersPageConfigurationContext.Provider>
  );
};

export default RoundPlayersPageConfigurationContextProvider;
