import { IDropPlayer } from "@/interfaces/AuctionDrops";
import { Position } from "@/interfaces/Position";

const KNOWN_POSITIONS = new Set<string>(Object.values(Position));

// the API may carry a position the client does not render yet; those are dropped rather than shown raw
export const playerPositions = (player: IDropPlayer) =>
  player.positions.filter((position) => KNOWN_POSITIONS.has(position));
