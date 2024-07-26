import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { IFilter } from "./interfaces";

export const defaultSearch = "";

export const defaultFilter: IFilter = {
  clubs: [],
  position: [],
  totalScore: {
    min: PlayersFilterConstants.TOTAL_SCORE_MIN,
    max: PlayersFilterConstants.TOTAL_SCORE_MAX,
  },
  baseScore: {
    min: PlayersFilterConstants.BASE_SCORE_MIN,
    max: PlayersFilterConstants.BASE_SCORE_MAX,
  },
  appearances: {
    min: PlayersFilterConstants.APPEARANCES_MIN,
    max: PlayersFilterConstants.APPEARANCES_MAX,
  },
  price: {
    min: PlayersFilterConstants.PRICE_MIN,
    max: PlayersFilterConstants.PRICE_MAX,
  },
  teamsCount: {
    min: PlayersFilterConstants.TEAMS_COUNT_MIN,
    max: PlayersFilterConstants.TEAMS_COUNT_MAX,
  },
  league: null,
  tournament: null,
};
