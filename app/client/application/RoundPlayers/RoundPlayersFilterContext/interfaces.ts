import { Position } from "@/interfaces/Position";

export interface IRoundPlayerFilter {
  clubs: number[],
  position: Position[],
  leagueId: number | null,
}
