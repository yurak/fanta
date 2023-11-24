import React from "react";
import styles from "./DataList.module.scss";

const DataList = <DataItem extends {} = {}>({
  dataSource,
  renderItem,
  itemKey,
}: {
  dataSource: DataItem[];
  renderItem: (item: DataItem) => React.ReactNode;
  itemKey: (item: DataItem) => string | number;
}) => {
  return (
    <div className={styles.list}>
      {dataSource.map((dataItem) => (
        <div key={itemKey(dataItem)} className={styles.item}>
          {renderItem(dataItem)}
        </div>
      ))}
    </div>
  );
};

export default DataList;
