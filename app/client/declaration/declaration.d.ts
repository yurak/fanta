declare module "*.scss";
declare module "*.json";
declare module "*.png";
declare module "*.svg" {
  const content: React.FunctionComponent<React.SVGAttributes<SVGElement>>;
  export default content;
}
