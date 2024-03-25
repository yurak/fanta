import { useMemo } from "react";
import axios from "axios";
import { useDebounceValue } from "usehooks-ts";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { IPlayer } from "@/interfaces/Player";
import { ICollectionResponse } from "@/interfaces/api/Response";
import { SortOrder } from "@/ui/Table/interfaces";

export const usePlayers = ({
  search,
  sortBy,
  sortOrder,
  filters,
}: {
  search: string,
  sortBy?: string | null,
  sortOrder?: SortOrder | null,
  filters: {
    position: string[],
  },
}) => {
  const filter = useMemo(
    () => ({
      name: search,
      position: filters.position,
    }),
    [search, filters]
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

  const [debouncedFilter] = useDebounceValue(filter, 500);

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
