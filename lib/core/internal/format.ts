type OwnerContextRecord = {
  owner_user_id?: string | null;
  workspace_id?: string | null;
  organization_id?: string | null;
};

function toNumber(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function formatShortId(id: string | null | undefined): string {
  if (!id) {
    return "None";
  }

  if (id.length <= 12) {
    return id;
  }

  return `${id.slice(0, 8)}...${id.slice(-4)}`;
}

export function formatMoney(value: number | string | null | undefined): string {
  const amount = toNumber(value);

  if (amount === null) {
    return "-";
  }

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
}

export function formatBasis(value: number | string | null | undefined): string {
  const amount = toNumber(value);

  if (amount === null) {
    return "Missing basis";
  }

  if (amount === 0) {
    return "$0.00 known";
  }

  return formatMoney(amount);
}

export function formatCurrentValue(
  value: number | string | null | undefined,
): string {
  const amount = toNumber(value);

  if (amount === null) {
    return "No comp saved";
  }

  return formatMoney(amount);
}

export function formatOwnerContext(record: OwnerContextRecord): string {
  if (record.owner_user_id) {
    return `User ${formatShortId(record.owner_user_id)}`;
  }

  if (record.workspace_id) {
    return `Workspace ${formatShortId(record.workspace_id)}`;
  }

  if (record.organization_id) {
    return `Organization ${formatShortId(record.organization_id)}`;
  }

  return "Unknown";
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("en-US", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

export function formatDate(value: string | null | undefined): string {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("en-US", {
    dateStyle: "medium",
  }).format(date);
}

export function formatEnumLabel(value: string | null | undefined): string {
  if (!value) {
    return "-";
  }

  return value
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}
