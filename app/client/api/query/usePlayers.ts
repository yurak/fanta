import { useMemo } from "react";
import axios from "axios";
import { useDebounceValue } from "usehooks-ts";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { IPlayer } from "@/interfaces/Player";
import { ICollectionResponse } from "@/interfaces/api/Response";
import { SortOrder } from "@/ui/Table/interfaces";
import { IFilter } from "@/application/Players/PlayersFilterContext/interfaces";

export const usePlayers = ({
  search,
  sortBy,
  sortOrder,
  filter,
}: {
  search: string,
  sortBy?: string | null,
  sortOrder?: SortOrder | null,
  filter: IFilter,
}) => {
  const _filter = useMemo(
    () => ({
      name: search,
      position: filter.position,
      base_score: filter.baseScore,
      total_score: filter.totalScore,
      app: filter.appearances,
      price: filter.price,
    }),
    [search, filter]
  );

  const order = useMemo(() => {
    if (!sortBy) {
      return undefined;
    }

    return {
      field: sortBy,
      direction: sortOrder,
    };
  }, [sortBy, sortOrder]);

  const [debouncedFilter] = useDebounceValue(_filter, 500);

  const query = useInfiniteQuery<ICollectionResponse<IPlayer[]>>({
    staleTime: 1000 * 60 * 10, // 10 minutes
    initialPageParam: 1,
    queryKey: ["players", debouncedFilter, order],
    queryFn: async ({ signal, pageParam: pageNumber }) => {
      return (
        await axios.get<ICollectionResponse<IPlayer[]>>("/players", {
          params: {
            filter: debouncedFilter,
            order,
            page: {
              number: pageNumber,
              size: 25,
            },
          },
          signal,
        })
      ).data;
    },
    placeholderData: keepPreviousData,
    getNextPageParam: ({ meta: { page } }) => {
      return page.current_page < page.total_pages ? page.current_page + 1 : undefined;
    },
  });

  return query;
};
