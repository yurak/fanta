import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ILeague } from "../../interfaces/League";

export const useLeagues = () => {
  const query = useQuery({
    queryKey: ["leagues"],
    queryFn: async () => {
      return (await axios.get<IResponse<ILeague[]>>("/leagues")).data.data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
