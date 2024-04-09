import { IPayloadFilter, IPayloadSort } from "@/api/query/usePlayers";
import { SortOrder } from "@/ui/Table/interfaces";
import { RangeSliderValueType } from "@/ui/RangeSlider";
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

export const filterToRequestFormat = (filter: IFilter, search: string): IPayloadFilter => {
  return {
    name: search,
    position: filter.position,
    total_score: justifyRangeSliderValue(filter.totalScore, defaultFilter.totalScore),
    teams_count: justifyRangeSliderValue(filter.teamsCount, defaultFilter.teamsCount),
    base_score: justifyRangeSliderValue(filter.baseScore, defaultFilter.baseScore),
    app: justifyRangeSliderValue(filter.appearances, defaultFilter.appearances),
    price: justifyRangeSliderValue(filter.price, defaultFilter.price),
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
