import { useQuery } from "@tanstack/react-query";
import { ISeason } from "../../interfaces/Season";

export const useSeasons = () => {
  const query = useQuery({
    queryKey: ["seasons"],
    queryFn: () =>
      fetch("/api/seasons")
        .then((res) => res.json())
        .then((res) => res.data as Promise<ISeason[]>),
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
