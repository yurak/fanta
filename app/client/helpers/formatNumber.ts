export const formatNumber = (value: number) => {
  return Intl.NumberFormat().format(value);
};
