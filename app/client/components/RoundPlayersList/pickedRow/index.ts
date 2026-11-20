import styles from "./pickedRow.module.scss";

// Green for the starting eleven, amber for the bench — the same pair the lineup picker uses, so
// the colours mean the same thing wherever they turn up.
export const pickedClass = (picked: "main" | "bench" | null) => {
  if (picked === "main") return styles.pickedMain;
  if (picked === "bench") return styles.pickedBench;

  return undefined;
};
