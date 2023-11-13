import { useQuery } from "@tanstack/react-query";
import { ILeague } from "../../interfaces/League";

export const useLeagues = () => {
  const query = useQuery({
    queryKey: ["leagues"],
    queryFn: () =>
      fetch("/api/leagues")
        .then((res) => res.json())
        .then((res) => res.data as Promise<ILeague[]>),
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
