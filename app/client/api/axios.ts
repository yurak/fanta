import axios from "axios";
import qs from "qs";

axios.defaults.baseURL = "/api";
axios.defaults.paramsSerializer = (params) => {
  return qs.stringify(params, {
    arrayFormat: "brackets",
    encodeValuesOnly: true,
  });
};

// Rails CSRF: send the token from csrf_meta_tags on mutating requests (session-cookie auth).
const SAFE_METHODS = ["get", "head", "options"];
axios.interceptors.request.use((config) => {
  const method = (config.method || "get").toLowerCase();
  if (!SAFE_METHODS.includes(method)) {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");
    if (token) config.headers.set("X-CSRF-Token", token);
  }
  return config;
});
