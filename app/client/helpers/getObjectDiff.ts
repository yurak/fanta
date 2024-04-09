export const getObjectDiffKeys = (obj1: object, obj2: object): string[] => {
  const allKeys = [...new Set([...Object.keys(obj1), ...Object.keys(obj2)])];

  return allKeys.reduce<string[]>((diff, key) => {
    const obj1Value = obj1[key];
    const obj2Value = obj2[key];

    if (typeof obj1Value !== typeof obj2Value) {
      return diff;
    }

    if (Array.isArray(obj1Value) && Array.isArray(obj2Value)) {
      const isEqual =
        obj1Value.every((key) => obj2Value.includes(key)) &&
        obj2Value.every((key) => obj1Value.includes(key));

      if (isEqual) {
        return diff;
      }

      return [...diff, key];
    }

    if (typeof obj1Value === "object" && typeof obj2Value === "object") {
      const childDiffKeys = getObjectDiffKeys(obj1Value, obj2Value);

      if (childDiffKeys.length === 0) {
        return diff;
      }

      return [...diff, key];
    }

    if (obj1Value === obj2Value) {
      return diff;
    }

    return [...diff, key];
  }, []);
};
