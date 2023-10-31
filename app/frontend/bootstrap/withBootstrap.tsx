import { useSSR } from "react-i18next";
import { resources } from "../locales/resources";
import { AppProvider } from "./AppProvider";

export const withBootstrap = (Component: React.ElementType) => (props, railsContext) => {
  return () => {
    useSSR(resources, railsContext.i18nLocale);

    return (
      <AppProvider>
        <Component {...props} />
      </AppProvider>
    );
  };
};
