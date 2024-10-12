import { createContext, useContext } from "react";
import { useCustomSearchParams } from "./useCustomSearchParams";

const SearchParamsContext = createContext<null | ReturnType<typeof useCustomSearchParams>>(null);

export const useSearchParamsContext = () => {
  const context = useContext(SearchParamsContext);

  if (!context) {
    throw new Error("useSearchParamsContext must be used within a SearchParamsContext");
  }

  return context;
};

const SearchParamsContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <SearchParamsContext.Provider value={useCustomSearchParams()}>
      {children}
    </SearchParamsContext.Provider>
  );
};

export default SearchParamsContextProvider;
