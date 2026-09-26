import { useState } from "react";
import DefaultLogo from "@/assets/icons/noTeam.svg";

const ClubLogo = ({ src, alt }: { src?: string | null, alt?: string }) => {
  const [failed, setFailed] = useState(false);

  if (!src || failed) return <DefaultLogo />;

  return <img src={src} alt={alt ?? ""} onError={() => setFailed(true)} />;
};

export default ClubLogo;
