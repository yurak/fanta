import { ReactNode, useEffect, useRef } from "react";
import { createPortal } from "react-dom";

const createPortalRoot = (id: string) => {
  const drawerRoot = document.createElement("div");
  drawerRoot.setAttribute("id", id);

  return drawerRoot;
};

export const useCreatePortal = (id: string) => {
  const bodyRef = useRef(document.body);
  const portalRef = useRef(document.getElementById(id) ?? createPortalRoot(id));

  useEffect(() => {
    const element = document.getElementById(id);

    if (element) {
      portalRef.current = element;
    } else {
      bodyRef.current.appendChild(portalRef.current);
    }
  }, []);

  return (children: ReactNode) => createPortal(children, portalRef.current);
};
