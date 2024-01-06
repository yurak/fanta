import { ILeague } from "../../interfaces/League";
import { ITournament } from "../../interfaces/Tournament";

export interface ILeaguesWithTournament extends ILeague {
  tournament: ITournament | null,
}
