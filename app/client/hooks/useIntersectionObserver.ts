import { useCallback, useRef, useState } from "react";

export const useIntersectionObserver = <T extends Element>({
  threshold = 1,
  root = null,
  rootMargin = "0px",
}: IntersectionObserverInit = {}): [
  React.RefCallback<T>,
  IntersectionObserverEntry | undefined
] => {
  const [entry, setEntry] = useState<IntersectionObserverEntry>();
  const previousObserver = useRef<IntersectionObserver | null>(null);

  const customRef: React.RefCallback<T> = useCallback(
    (node) => {
      if (previousObserver.current) {
        previousObserver.current.disconnect();
        previousObserver.current = null;
      }

      if (node?.nodeType === Node.ELEMENT_NODE) {
        const observer = new IntersectionObserver(
          ([entry]) => {
            setEntry(entry);
          },
          { threshold, root, rootMargin }
        );

        observer.observe(node);
        previousObserver.current = observer;
      }
    },
    [threshold, root, rootMargin]
  );

  return [customRef, entry];
};
