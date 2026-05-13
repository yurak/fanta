import axios from "axios";
import qs from "qs";

axios.defaults.baseURL = "/api";
axios.defaults.paramsSerializer = (params) => {
  return qs.stringify(params, {
    arrayFormat: "brackets",
    encodeValuesOnly: true,
  });
};
