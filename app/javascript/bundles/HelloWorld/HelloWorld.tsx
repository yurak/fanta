import { useState, useEffect } from "react";
import style from "./HelloWorld.module.scss";

interface IProps {
  name: string;
}

const HelloWorld = (props: IProps) => {
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
