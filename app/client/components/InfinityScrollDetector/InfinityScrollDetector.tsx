import { useEffect, useRef } from "react";
import { useDebounceCallback } from "usehooks-ts";
import styles from "./InfinityScrollDetector.module.scss";

const InfinityScrollDetector = ({ loadMore }: { loadMore: () => void }) => {
  const ref = useRef<HTMLDivElement>(null);

  const debouncedLoadMore = useDebounceCallback(loadMore, 200);

  useEffect(() => {
    const handleScroll = () => {
      const { scrollTop, clientHeight } = document.documentElement;

      const scrollBottom = scrollTop + clientHeight;
      const elementPosition = ref.current?.offsetTop ?? 0;
      const offset = clientHeight / 2;

      if (scrollBottom >= elementPosition - offset) {
        debouncedLoadMore();
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => {
      window.removeEventListener("scroll", handleScroll);
    };
  }, [debouncedLoadMore]);

  return <div ref={ref} className={styles.infinityScrollDetector} />;
};

export default InfinityScrollDetector;
