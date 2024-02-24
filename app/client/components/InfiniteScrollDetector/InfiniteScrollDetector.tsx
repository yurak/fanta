import React, { useEffect } from "react";
import { useIntersectionObserver } from "@/hooks/useIntersectionObserver";

const InfiniteScrollDetector = ({
  children,
  loadMore,
  className,
}: {
  children: React.ReactNode,
  loadMore: () => void,
  className: string,
}) => {
  const [ref, isIntersecting] = useIntersectionObserver({
    rootMargin: "100%",
  });

  useEffect(() => {
    if (isIntersecting) {
      loadMore();
    }
  }, [isIntersecting]);

  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  );
};

export default InfiniteScrollDetector;
