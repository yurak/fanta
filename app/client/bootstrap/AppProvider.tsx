import React from "react";
import { initReactI18next } from "react-i18next";
import i18n from "i18next";
import { resources } from "../locales/resources";

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

export const AppProvider = ({ children }: IProps) => <>{children}</>;
