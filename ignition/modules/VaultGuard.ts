import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("VaultGuardModule", (m) => {
  const vaultGuard = m.contract("VaultGuard");

  // Example: create a will with 2 nominees and a dummy encrypted hash
  const nominees = [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222"
  ];
  const initialDeadline = BigInt(Math.floor(Date.now() / 1000) + 86400); // now + 1 day
  const encryptedHash = "0x" + "00".repeat(32);

  m.call(vaultGuard, "createWill", [initialDeadline, nominees, encryptedHash]);

  return { vaultGuard };
});