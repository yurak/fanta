import React, { useEffect } from "react";
import { useIntersectionObserver } from "@/hooks/useIntersectionObserver";

const InfinityScrollDetector = ({
  children,
  loadMore,
  className,
}: {
  children: React.ReactNode,
  loadMore: () => void,
  className?: string,
}) => {
  const [ref, isIntersecting] = useIntersectionObserver();

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

export default InfinityScrollDetector;
