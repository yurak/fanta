import { Position } from "@/interfaces/Position";
import { defaultFilter } from "./constants";
import { IRoundPlayerFilter } from "./interfaces";

const arraySeparator = ",";
const validPositions = new Set<string>(Object.values(Position));

export const decodeFilter = (filter?: Record<string, string>): IRoundPlayerFilter => {
  try {
    if (!filter) {
      return defaultFilter;
    }

    return {
      position:
        (filter.pos?.split(arraySeparator).filter((pos) => validPositions.has(pos)) as Position[]) ??
        defaultFilter.position,
      clubs: filter.clubs?.split(arraySeparator).map((club) => Number(club)) ?? defaultFilter.clubs,
      leagueId: filter.league ? Number(filter.league) : null,
    };
  } catch (e) {
    return defaultFilter;
  }
};

export const encodeFilter = (filter: IRoundPlayerFilter): Record<string, string | null> => {
  return {
    pos: filter.position.length > 0 ? filter.position.join(arraySeparator) : null,
    clubs: filter.clubs.length > 0 ? filter.clubs.join(arraySeparator) : null,
    league: filter.leagueId ? String(filter.leagueId) : null,
  };
};
