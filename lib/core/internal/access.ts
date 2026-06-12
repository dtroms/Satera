export async function requireInternalAccess(): Promise<void> {
  if (process.env.NODE_ENV !== "production") {
    return;
  }

  // TODO: Replace this placeholder with real platform_admin authorization.
  // Do not fake production access. The internal inspector can expose private
  // Core truth records and must require a verified platform_admin role.
  throw new Error(
    "Satera Core Internal Inspector requires platform_admin authorization before production use.",
  );
}
