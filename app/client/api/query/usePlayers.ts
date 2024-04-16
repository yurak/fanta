import axios from "axios";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { IPlayer } from "@/interfaces/Player";
import { ICollectionResponse } from "@/interfaces/api/Response";
import { SortOrder } from "@/ui/Table/interfaces";
import { RangeSliderValueType } from "@/ui/RangeSlider";

export interface IPayloadFilter {
  name?: string,
  position?: string[],
  club_id?: number[],
  total_score?: Partial<RangeSliderValueType>,
  base_score?: Partial<RangeSliderValueType>,
  teams_count?: Partial<RangeSliderValueType>,
  app?: Partial<RangeSliderValueType>,
  price?: Partial<RangeSliderValueType>,
}

export interface IPayloadSort {
  field: string,
  direction: SortOrder,
}

export const usePlayers = ({
  sort: order,
  filter,
}: {
  filter: IPayloadFilter,
  sort?: IPayloadSort,
}) => {
  const query = useInfiniteQuery<ICollectionResponse<IPlayer[]>>({
    staleTime: 1000 * 60 * 10, // 10 minutes
    initialPageParam: 1,
    queryKey: ["players", filter, order],
    queryFn: async ({ signal, pageParam: pageNumber }) => {
      return (
        await axios.get<ICollectionResponse<IPlayer[]>>("/players", {
          params: {
            filter,
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
