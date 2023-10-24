import { useState, useEffect } from "react";
import { initReactI18next, useTranslation } from "react-i18next";
import i18n from "i18next";
import locales from "../../locales.json";
import style from "./HelloWorld.module.scss";

i18n.use(initReactI18next).init({
  resources: {
    en: {
      translation: locales.en,
    },
    ua: {
      translation: locales.au,
    },
  },
  lng: "en", // if you're using a language detector, do not define the lng option
  fallbackLng: "en",
  interpolation: {
    escapeValue: false,
  },
});

interface IProps {
  name: string;
}

const HelloWorld = (props: IProps) => {
  const { t } = useTranslation();

  const [name, setName] = useState(props.name);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  return (
    <div>
      <h3>Hello, {name}!</h3>
      <hr />
      <h1>{isClient ? "This is never prerendered" : "Prerendered"}</h1>
      <p>Translations are ready: {t("header.bid_made")}</p>
      <form>
        <label className={style.bright} htmlFor="name">
          Say hello to:
          <input id="name" type="text" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
      </form>
    </div>
  );
};

export default HelloWorld;
