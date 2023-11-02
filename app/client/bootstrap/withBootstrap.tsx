import React from "react";
import { RailsContext } from "react-on-rails/node_package/lib/types";
import { useSSR } from "react-i18next";
import { resources } from "../locales/resources";
import { AppProvider } from "./AppProvider";

export const withBootstrap =
  <T extends {}>(Component: React.ComponentType<T>) =>
  (props: T, railsContext: RailsContext) => {
    return () => {
      useSSR(resources, railsContext.i18nLocale);

      return (
        <AppProvider>
          <Component {...props} />
        </AppProvider>
      );
    };
  };
