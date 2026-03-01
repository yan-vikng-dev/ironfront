import { readFileSync } from "fs";
import { join } from "path";

export type CatalogTank = {
  dollar_cost: number;
  allowed_shell_ids: string[];
};

export type CatalogShell = {
  unlock_cost: number;
};

export type Catalog = {
  tanks: Record<string, CatalogTank>;
  shells: Record<string, CatalogShell>;
};

const CATALOG_PATH = join(process.cwd(), "catalog", "catalog.json");

let cachedCatalog: Catalog | null = null;

export function loadCatalog(): Catalog {
  if (cachedCatalog) return cachedCatalog;
  try {
    const raw = readFileSync(CATALOG_PATH, "utf8");
    cachedCatalog = JSON.parse(raw) as Catalog;
    return cachedCatalog;
  } catch (error) {
    throw new Error(
      `catalog.json not found at ${CATALOG_PATH}. Run \`just build\` from repo root to export from game.`,
      { cause: error }
    );
  }
}
