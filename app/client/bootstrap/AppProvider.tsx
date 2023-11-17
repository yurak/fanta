import React from "react";
import "react-loading-skeleton/dist/skeleton.css";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { initReactI18next } from "react-i18next";
import i18n from "i18next";
import "../api/axios";
import { resources } from "../locales/resources";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 10 * 60 * 1000, // 10min
    },
  },
});

i18n.use(initReactI18next).init({
  resources,
  lng: typeof window === "object" ? window.i18nLocale : "en",
  fallbackLng: "en",
  interpolation: {
    escapeValue: false,
  },
});

interface IProps {
  children: React.ReactNode;
}

export const AppProvider = ({ children }: IProps) => (
  <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
);
