import { createContext, useContext, useEffect, useState } from "react";
import { IRoundPlayerFilter } from "./interfaces";
import { useRoundPlayersContext } from "../RoundPlayersContext";

const useRoundPlayersFilter = ({
  shouldApplyOnValueChange,
}: {
  shouldApplyOnValueChange?: boolean,
}) => {
  const {
    filterValues: globalFilterValues,
    setFilterValues: setGlobalFilterValues,
    setFilterValuesWithDebounce: setGlobalFilterValuesWithDebounce,
  } = useRoundPlayersContext();

  const [filterValues, setFilterValues] = useState<IRoundPlayerFilter>(globalFilterValues);

  const onChangeValue =
    <T extends keyof IRoundPlayerFilter>(name: T) =>
    (value: IRoundPlayerFilter[T]) => {
      setFilterValues((filter) => ({
        ...filter,
        [name]: value,
      }));
    };

  useEffect(() => {
    if (globalFilterValues !== filterValues) {
      setFilterValues(globalFilterValues);
    }
  }, [globalFilterValues]);

  useEffect(() => {
    if (globalFilterValues !== filterValues && shouldApplyOnValueChange) {
      setGlobalFilterValuesWithDebounce(filterValues);
    }
  }, [filterValues, shouldApplyOnValueChange]);

  const applyFilter = () => {
    setGlobalFilterValues(filterValues);
  };

  return {
    filterValues,
    onChangeValue,
    applyFilter,
  };
};

const RoundPlayersFilterContext = createContext<null | ReturnType<typeof useRoundPlayersFilter>>(
  null
);

export const useRoundPlayersFilterContext = () => {
  const context = useContext(RoundPlayersFilterContext);

  if (!context) {
    throw new Error("useRoundPlayersFilterContext must be used within a RoundPlayersFilterContext");
  }

  return context;
};

const RoundPlayersFilterContextProvider = ({
  children,
  shouldApplyOnValueChange,
}: {
  children: React.ReactNode,
  shouldApplyOnValueChange?: boolean,
}) => {
  return (
    <RoundPlayersFilterContext.Provider value={useRoundPlayersFilter({ shouldApplyOnValueChange })}>
      {children}
    </RoundPlayersFilterContext.Provider>
  );
};

export default RoundPlayersFilterContextProvider;
