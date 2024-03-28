import { createContext, useContext, useEffect, useState } from "react";
import { IFilter } from "./interfaces";
import { usePlayersContext } from "../PlayersContext";

const usePlayersFilter = ({ shouldApplyOnValueChange }: { shouldApplyOnValueChange?: boolean }) => {
  const { filter, setFilter } = usePlayersContext();

  const [filterValues, setFilterValues] = useState<IFilter>(filter);

  const onChangeValue =
    <T extends keyof IFilter>(name: T) =>
    (value: IFilter[T]) => {
      setFilterValues((filter) => ({
        ...filter,
        [name]: value,
      }));
    };

  useEffect(() => {
    if (filter !== filterValues) {
      setFilterValues(filter);
    }
  }, [filter]);

  useEffect(() => {
    if (filter !== filterValues && shouldApplyOnValueChange) {
      setFilter(filterValues);
    }
  }, [filterValues, shouldApplyOnValueChange]);

  const applyFilter = () => {
    setFilter(filterValues);
  };

  return {
    filterValues,
    onChangeValue,
    applyFilter,
  };
};

const PlayersFilterContext = createContext<null | ReturnType<typeof usePlayersFilter>>(null);

export const usePlayersFilterContext = () => {
  const context = useContext(PlayersFilterContext);

  if (!context) {
    throw new Error("usePlayersFilterContext must be used within a PlayersFilterContext");
  }

  return context;
};

const PlayersFilterContextProvider = ({
  children,
  shouldApplyOnValueChange,
}: {
  children: React.ReactNode,
  shouldApplyOnValueChange?: boolean,
}) => {
  return (
    <PlayersFilterContext.Provider value={usePlayersFilter({ shouldApplyOnValueChange })}>
      {children}
    </PlayersFilterContext.Provider>
  );
};

export default PlayersFilterContextProvider;
