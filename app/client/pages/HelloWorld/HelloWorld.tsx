import { useState } from "react";
import { useTranslation } from "react-i18next";
import { withBootstrap } from "../../bootstrap/withBootstrap";
import style from "./HelloWorld.module.scss";

const HelloWorld = ({ name: defaultName }: { name: string }) => {
  const { t } = useTranslation();

  const [name, setName] = useState(defaultName);

  return (
    <div>
      <h3>Hello, {name}!</h3>
      <hr />
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

export default withBootstrap(HelloWorld);
