import { useCallback, useState } from "react";
import { ILeaguesWithTournament } from "../interfaces";

export const useFinished = () => {
  const [showFinished, setShowFinished] = useState(false);

  const filterFinished = useCallback(
    (leagues: ILeaguesWithTournament[]) => {
      if (showFinished) {
        return leagues;
      }

      return leagues.filter((league) => league.status !== "archived");
    },
    [showFinished]
  );

  return {
    showFinished,
    setShowFinished,
    filterFinished,
  };
};
