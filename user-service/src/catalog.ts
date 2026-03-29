export type CatalogTank = {
  dollar_cost: number;
};

export type CatalogShell = {
  unlock_cost: number;
};

export type Catalog = {
  tanks: Record<string, CatalogTank>;
  shells: Record<string, CatalogShell>;
};

export const catalog: Catalog = {
  tanks: {
    m4a1_sherman: { dollar_cost: 0 },
    tiger_1: { dollar_cost: 500_000 }
  },
  shells: {
    "m4a1_sherman.m75": { unlock_cost: 10_000 },
    "m4a1_sherman.m82": { unlock_cost: 12_000 },
    "m4a1_sherman.m63": { unlock_cost: 8_000 },
    "m4a1_sherman.m75_t": { unlock_cost: 10_000 },
    "m4a1_sherman.m63_t": { unlock_cost: 8_500 },
    "tiger_1.pzgr39": { unlock_cost: 10_000 },
    "tiger_1.pzgr39_t": { unlock_cost: 10_000 },
    "tiger_1.pzgr40": { unlock_cost: 20_000 }
  }
};
