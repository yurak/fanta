import { IRoundPlayerPayloadFilter } from "@/api/query/useRoundPlayers";
import { IPayloadSort } from "@/api/query/usePlayers";
import { SortOrder } from "@/hooks/useHistorySort";
import { IRoundPlayerFilter } from "./interfaces";

export const filterToRequestFormat = (
  filter: IRoundPlayerFilter,
  search: string
): IRoundPlayerPayloadFilter => {
  return {
    name: search.trim().length > 0 ? search.trim() : undefined,
    position: filter.position.length > 0 ? filter.position : undefined,
    club_id: filter.clubs.length > 0 ? filter.clubs : undefined,
    league_id: filter.leagueId ?? undefined,
  };
};

export const sortToRequestFormat = (
  sortBy?: string | null,
  sortOrder?: SortOrder | null
): IPayloadSort | undefined => {
  if (sortBy && sortOrder) {
    return {
      field: sortBy,
      direction: sortOrder,
    };
  }

  return undefined;
};
