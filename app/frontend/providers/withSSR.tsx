import { useSSR } from "react-i18next";
import { resources } from "../locales/resources";

export const withSSR = (Component: React.ElementType) => (props, railsContext) => {
  return () => {
    useSSR(resources, railsContext.i18nLocale);

    return <Component {...props} />;
  };
};
