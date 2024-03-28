export const isArrayEquals = (array1: number[], array2: number[]) => {
  if (array1.length !== array2.length) {
    return false;
  }

  return array1.every((value, index) => array2[index] === value);
};
