export const sorters = {
  string: <T extends object = object>(key: keyof T) => {
    return (object1: T, object2: T) => {
      return (object1[key] as string).localeCompare(object2[key] as string);
    };
  },
  numbers: <T extends object = object>(key: keyof T, toNumber = false, reverse = false) => {
    if (toNumber) {
      return (object1: T, object2: T) => {
        const leftObject = reverse ? object1 : object2;
        const rightObject = reverse ? object2 : object1;

        return Number(leftObject[key]) - Number(rightObject[key]);
      };
    }

    return (object1: T, object2: T) => {
      const leftObject = reverse ? object1 : object2;
      const rightObject = reverse ? object2 : object1;

      return (leftObject[key] as number) - (rightObject[key] as number);
    };
  },
};
