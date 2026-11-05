import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import { formatNumber } from "@/helpers/formatNumber";
import styles from "./MainAppearances.module.scss";

// The count of starting elevens this player is in. A button rather than plain text once the
// count is above nought, because the teams behind it are worth seeing.
const MainAppearances = ({
  player,
  onOpen,
}: {
  player: IRoundPlayer,
  onOpen: (player: IRoundPlayer) => void,
}) => {
  if (player.main_appearances === null) return <>-</>;
  if (player.main_appearances === 0) return <>{formatNumber(0)}</>;

  return (
    <button type="button" className={styles.count} onClick={() => onOpen(player)}>
      {formatNumber(player.main_appearances)}
    </button>
  );
};

export default MainAppearances;
