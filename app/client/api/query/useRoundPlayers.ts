import axios from "axios";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import { ICollectionResponse } from "@/interfaces/api/Response";
import { Position } from "@/interfaces/Position";
import { IPayloadSort } from "@/api/query/usePlayers";

export interface IRoundPlayerPayloadFilter {
  name?: string,
  position?: Position[],
  club_id?: number[],
  league_id?: number,
}

export const useRoundPlayers = ({
  roundId,
  filter,
  sort: order,
}: {
  roundId: number,
  filter: IRoundPlayerPayloadFilter,
  sort?: IPayloadSort,
}) => {
  const query = useInfiniteQuery<ICollectionResponse<IRoundPlayer[]>>({
    staleTime: 1000 * 60 * 10, // 10 minutes
    initialPageParam: 1,
    queryKey: ["round_players", roundId, filter, order],
    queryFn: async ({ signal, pageParam: pageNumber }) => {
      return (
        await axios.get<ICollectionResponse<IRoundPlayer[]>>(
          `/tournament_rounds/${roundId}/round_players`,
          {
            params: {
              filter,
              order,
              page: {
                number: pageNumber,
                size: 25,
              },
            },
            signal,
          }
        )
      ).data;
    },
    placeholderData: keepPreviousData,
    getNextPageParam: ({ meta: { page } }) => {
      return page.current_page < page.total_pages ? page.current_page + 1 : undefined;
    },
  });

  return query;
};
