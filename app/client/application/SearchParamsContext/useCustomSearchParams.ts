import { useCallback, useRef } from "react";
import { useDebounceCallback } from "usehooks-ts";

type ParamsType = Record<string, string>;

type NavigateOptions = {
  replace?: boolean,
};

class CustomURLSearchParams {
  private params: ParamsType;

  constructor(search: string) {
    this.params = this.parseParams(search);
  }

  private parseParams(search: string) {
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

  getAll() {
    return this.params;
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

const navigate = (url: string, { replace = false }: NavigateOptions = {}) => {
  if (replace) {
    window.history.replaceState(null, "", url);
  } else {
    window.history.pushState(null, "", url);
  }

  window.dispatchEvent(new PopStateEvent("popstate"));
};

export const useCustomSearchParams = () => {
  const navigateWithDebouce = useDebounceCallback(navigate, 0);

  const searchParams = useRef(new CustomURLSearchParams(window.location.search));

  const setSearchParams = useCallback(
    (
      callback: (params: CustomURLSearchParams) => CustomURLSearchParams,
      navigateOptions?: NavigateOptions
    ) => {
      const newParams = callback(searchParams.current).toString();
      const path = newParams.length > 0 ? `?${newParams}` : window.location.pathname;
      navigateWithDebouce(path, navigateOptions);
    },
    [navigate, searchParams]
  );

  return { searchParams: searchParams.current, setSearchParams };
};
