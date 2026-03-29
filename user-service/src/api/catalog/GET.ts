import { Hono } from "hono";
import { catalog } from "../../catalog.js";

export const route = new Hono().get("/", (context) => {
  return context.json(catalog);
});
