import PropTypes from "prop-types";
import React, { useState, useEffect } from "react";
import style from "./HelloWorld.module.css";

const HelloWorld = (props) => {
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

HelloWorld.propTypes = {
  name: PropTypes.string.isRequired, // this is passed from the Rails view
};

export default HelloWorld;
