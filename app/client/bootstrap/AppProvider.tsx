import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import "react-loading-skeleton/dist/skeleton.css";
import { initReactI18next } from "react-i18next";
import i18n from "i18next";
import "@/api/axios";
import { resources } from "@/locales/resources";
import AppContextProvider from "@/application/AppContext";
import { useQueryClient } from "./useQueryClient";
import SearchParamsContextProvider from "@/application/SearchParamsContext";

i18n.use(initReactI18next).init({
  resources,
  lng: typeof window === "object" ? window.i18nLocale : "en",
  fallbackLng: "en",
  interpolation: {
    escapeValue: false,
  },
});

interface IProps {
  children: React.ReactNode,
}

export const AppProvider = ({ children }: IProps) => {
  const { queryClient, persistOptions } = useQueryClient();

  return (
    <AppContextProvider>
      <SearchParamsContextProvider>
        <PersistQueryClientProvider client={queryClient} persistOptions={persistOptions}>
          {children}
          <ReactQueryDevtools />
        </PersistQueryClientProvider>
      </SearchParamsContextProvider>
    </AppContextProvider>
  );
};
