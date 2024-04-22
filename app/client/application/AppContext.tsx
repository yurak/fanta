import { createContext, useContext } from "react";

const useApp = () => {
  const italPositionNaming = typeof window === "object" ? window.italPositionNaming : false;

  return {
    italPositionNaming,
  };
};

const AppContext = createContext<null | ReturnType<typeof useApp>>(null);

export const useAppContext = () => {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error("useAppContext must be used within a AppContext");
  }

  return context;
};

const AppContextProvider = ({ children }: { children: React.ReactNode }) => {
  return <AppContext.Provider value={useApp()}>{children}</AppContext.Provider>;
};

export default AppContextProvider;
