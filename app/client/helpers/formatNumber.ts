import React from "react";

interface IOptions extends Intl.NumberFormatOptions {
  zeroFallback?: React.ReactNode,
  suffix?: string,
}

export const formatNumber = (
  value: number,
  { zeroFallback, suffix, ...options }: IOptions = {}
) => {
  if (value === 0) {
    return zeroFallback ?? 0;
  }

  return `${Intl.NumberFormat("en", {
    ...options,
  }).format(value)}${suffix ?? ""}`;
};
