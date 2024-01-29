export const sorters = {
  string: <T extends object = object>(key: keyof T) => {
    return (object1: T, object2: T) => {
      return (object1[key] as string).localeCompare(object2[key] as string);
    };
  },
  numbers: <T extends object = object>(key: keyof T, toNumber = false) => {
    if (toNumber) {
      return (object1: T, object2: T) => {
        return Number(object1[key]) - Number(object2[key]);
      };
    }

    return (object1: T, object2: T) => {
      return (object1[key] as number) - (object2[key] as number);
    };
  },
};
