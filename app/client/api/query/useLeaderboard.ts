import axios from "axios";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { ILeaderboardEntry, LeaderboardMetric } from "@/interfaces/Leaderboard";

export interface ILeaderboardResponse {
  data: ILeaderboardEntry[],
  meta: {
    page: {
      current_page: number,
      per_page: number,
      total_pages: number,
    },
    size: number,
    current_user: ILeaderboardEntry | null,
  },
}

export const LEADERBOARD_PAGE_SIZE = 20;

export const useLeaderboard = ({
  metric,
  includeNewbies,
  minMatches,
  tournamentId,
}: {
  metric: LeaderboardMetric,
  includeNewbies: boolean,
  minMatches: number,
  tournamentId: number | null,
}) => {
  return useInfiniteQuery<ILeaderboardResponse>({
    staleTime: 1000 * 60, // 1 minute
    initialPageParam: 1,
    queryKey: ["leaderboard", metric, includeNewbies, minMatches, tournamentId],
    queryFn: async ({ signal, pageParam: pageNumber }) =>
      (
        await axios.get<ILeaderboardResponse>("/leaderboard", {
          params: {
            metric,
            include_newbies: includeNewbies,
            min_matches: minMatches,
            tournament_id: tournamentId ?? undefined,
            page: {
              number: pageNumber,
              size: LEADERBOARD_PAGE_SIZE,
            },
          },
          signal,
        })
      ).data,
    placeholderData: keepPreviousData,
    getNextPageParam: ({ meta: { page } }) =>
      page.current_page < page.total_pages ? page.current_page + 1 : undefined,
  });
};
