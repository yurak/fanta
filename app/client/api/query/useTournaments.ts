import { useQuery } from "@tanstack/react-query";
import { ITournament } from "../../interfaces/Tournament";

export const useTournaments = () => {
  const query = useQuery({
    queryKey: ["tournaments"],
    queryFn: () =>
      fetch("/api/tournaments")
        .then((res) => res.json())
        .then((res) => res.data as Promise<ITournament[]>),
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
