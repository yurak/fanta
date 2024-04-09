import { useMemo, useCallback } from "react";
import { NavigateOptions, useLocation, useNavigate } from "react-router-dom";

type ParamsType = Record<string, string>;

class CustomURLSearchParams {
  params: ParamsType;

  constructor(search: string) {
    this.params = this.initParams(search);
  }

  private initParams(search: string) {
    if (!search) {
      return {};
    }

    const hasQueryString = search.includes("?");

    if (hasQueryString) {
      search = search.slice(search.indexOf("?") + 1);
    }

    return search
      .split("&")
      .map((string) => {
        const [key, value] = string.split("=");

        return {
          key: key as string,
          value: value as string,
        };
      })
      .reduce(
        (allParams, { key, value }) => ({
          ...allParams,
          [key]: value,
        }),
        {}
      );
  }

  set(key: string, value: string, encode?: boolean) {
    this.params[key] = encode ? encodeURIComponent(value) : value;
  }

  get(key: string, decode?: boolean) {
    const value = this.params[key];

    if (!value) {
      return value;
    }

    return decode ? decodeURIComponent(value) : value;
  }

  delete(key: string) {
    delete this.params[key];
  }

  toString() {
    return Object.keys(this.params)
      .filter((key) => Boolean(this.params[key]))
      .map((key) => [key, this.params[key]].join("="))
      .join("&");
  }
}

export const useCustomSearchParams = (): [
  CustomURLSearchParams,
  (
    callback: (params: CustomURLSearchParams) => CustomURLSearchParams,
    navigateOptions?: NavigateOptions
  ) => void
] => {
  const location = useLocation();
  const navigate = useNavigate();

  const searchParams = useMemo(() => new CustomURLSearchParams(location.search), [location.search]);

  const setSearchParams = useCallback(
    (
      callback: (params: CustomURLSearchParams) => CustomURLSearchParams,
      navigateOptions?: NavigateOptions
    ) => {
      const newParams = callback(searchParams).toString();
      const path = newParams.length > 0 ? `?${newParams}` : "";
      navigate(path, navigateOptions);
    },
    [navigate, searchParams]
  );

  return [searchParams, setSearchParams];
};
