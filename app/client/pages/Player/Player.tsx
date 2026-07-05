import { useParams } from "react-router-dom";
import PlayerPage from "@/components/PlayerPage";

const Player = () => {
  const params = useParams<{ playerId: string }>();
  const playerId = Number(params.playerId);

  return <PlayerPage id={playerId} />;
};

export default Player;
