import React from "react";
import {
  RailsContext,
  ReactComponentOrRenderFunction,
} from "react-on-rails/node_package/lib/types";
import { useSSR } from "react-i18next";
import { resources } from "../locales/resources";
import { AppProvider } from "./AppProvider";

export const withBootstrap =
  <T extends Record<string, any>>(
    Component: React.ComponentType<T>
  ): ReactComponentOrRenderFunction =>
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
