import Skeleton from "react-loading-skeleton";
import { useIntersectionObserver } from "@/hooks/useIntersectionObserver";
import { DefaultError, UseQueryResult } from "@tanstack/react-query";

export interface IBaseProps<TData> {
  children: (item: TData) => React.ReactNode,
  skeleton?: React.ReactNode,
}

interface IProps<TData, TError = DefaultError> extends IBaseProps<TData> {
  useQuery: (isIntersecting: boolean) => UseQueryResult<TData, TError>,
}

const QueryLoader = <TData, TError = DefaultError>({
  useQuery,
  skeleton = <Skeleton />,
  children,
}: IProps<TData, TError>) => {
  const [ref, isIntersecting] = useIntersectionObserver({
    rootMargin: "100%",
  });
  const { isLoading, data } = useQuery(isIntersecting);

  return <div ref={ref}>{isLoading || !data ? skeleton : children(data)}</div>;
};

export default QueryLoader;
