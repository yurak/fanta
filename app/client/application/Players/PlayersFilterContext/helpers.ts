import { IPayloadFilter, IPayloadSort } from "@/api/query/usePlayers";
import { RangeSliderValueType } from "@/ui/RangeSlider";
import { SortOrder } from "@/hooks/useHistorySort";
import { IFilter } from "./interfaces";
import { defaultFilter } from "./constants";

const justifyRangeSliderValue = (
  value: RangeSliderValueType,
  defaultValue: RangeSliderValueType
): Partial<RangeSliderValueType> | undefined => {
  if (value.min === defaultValue.min && value.max === defaultValue.max) {
    return undefined;
  }

  return {
    min: value.min > defaultValue.min ? value.min : undefined,
    max: value.max < defaultValue.max ? value.max : undefined,
  };
};

export const filterToRequestFormat = (
  filter: IFilter,
  search: string,
  defaultLeagueId?: number
): IPayloadFilter => {
  return {
    name: search.trim().length > 0 ? search.trim() : undefined,
    position: filter.position,
    club_id: filter.clubs,
    tournament_id: filter.tournaments,
    team_id: filter.teams,
    without_team: filter.withoutTeam || undefined,
    total_score: justifyRangeSliderValue(filter.totalScore, defaultFilter.totalScore),
    teams_count: justifyRangeSliderValue(filter.teamsCount, defaultFilter.teamsCount),
    base_score: justifyRangeSliderValue(filter.baseScore, defaultFilter.baseScore),
    app: justifyRangeSliderValue(filter.appearances, defaultFilter.appearances),
    minutes: justifyRangeSliderValue(filter.minutes, defaultFilter.minutes),
    price: justifyRangeSliderValue(filter.price, defaultFilter.price),
    league_id: defaultLeagueId,
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
