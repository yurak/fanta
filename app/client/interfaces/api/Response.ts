export interface IResponse<Data> {
  data: Data,
}

export interface ICollectionResponse<Data> extends IResponse<Data> {
  meta: {
    page: {
      current_page: number,
      per_page: number,
      total_pages: number,
    },
    size: number,
  },
}
