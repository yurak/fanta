import { RangeSliderValueType } from "@/ui/RangeSlider";
import { Position } from "@/interfaces/Position";
import { defaultFilter } from "./constants";
import { IFilter } from "./interfaces";

const rangeValueSeparator = "-";
const arraySeparator = ",";

const decodeRangeValue = (defaultRange: RangeSliderValueType, value?: string) => {
  if (!value) {
    return defaultRange;
  }

  const parsed = value.split(rangeValueSeparator);
  let min = Number(parsed[0]);
  let max = Number(parsed[1]);

  [min, max] = min > max ? [max, min] : [min, max];

  return {
    min: min ? Math.max(defaultRange.min, min) : defaultRange.min,
    max: max ? Math.min(defaultRange.max, max) : defaultRange.max,
  };
};

const decodeNumber = (value?: string) => {
  if (!value) {
    return null;
  }

  const numberValue = Number(value);

  if (isNaN(numberValue)) {
    return null;
  }

  return numberValue;
};

const encodeRangeValue = (
  defaultRange: RangeSliderValueType,
  rangeFilter: RangeSliderValueType
): string | null => {
  if (defaultRange.max === rangeFilter.max && defaultRange.min === rangeFilter.min) {
    return null;
  }

  return [rangeFilter.min, rangeFilter.max].join(rangeValueSeparator);
};

export const decodeFilter = (filter?: Record<string, string>): IFilter => {
  try {
    if (!filter) {
      return defaultFilter;
    }

    return {
      appearances: decodeRangeValue(defaultFilter.appearances, filter.apps),
      baseScore: decodeRangeValue(defaultFilter.baseScore, filter.bs),
      price: decodeRangeValue(defaultFilter.price, filter.price),
      totalScore: decodeRangeValue(defaultFilter.totalScore, filter.ts),
      teamsCount: decodeRangeValue(defaultFilter.teamsCount, filter.teams),
      position: (filter.pos?.split(arraySeparator) ?? defaultFilter.position) as Position[],
      clubs: filter.clubs?.split(arraySeparator).map((club) => Number(club)) ?? defaultFilter.clubs,
      league: decodeNumber(filter.league) ?? defaultFilter.league,
      tournament: decodeNumber(filter.tournament) ?? defaultFilter.tournament,
    };
  } catch (e) {
    return defaultFilter;
  }
};

export const encodeFilter = (filter: IFilter): Record<string, string | null> => {
  return {
    apps: encodeRangeValue(defaultFilter.appearances, filter.appearances),
    bs: encodeRangeValue(defaultFilter.baseScore, filter.baseScore),
    price: encodeRangeValue(defaultFilter.price, filter.price),
    ts: encodeRangeValue(defaultFilter.totalScore, filter.totalScore),
    teams: encodeRangeValue(defaultFilter.teamsCount, filter.teamsCount),
    pos: filter.position.join(arraySeparator),
    clubs: filter.clubs.join(arraySeparator),
    league: filter.league ? String(filter.league) : null,
    tournament: filter.tournament ? String(filter.tournament) : null,
  };
};
