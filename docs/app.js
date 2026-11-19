// AgentStreak frontend. Fill in STREAK_ADDRESS + DEPLOY_BLOCK after deployment.
const AGENT_ID = "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F";
const STREAK_ADDRESS = "0x2993602cb38eC33ff90AFcDdB3110Dd49A5C171B";
const DEPLOY_BLOCK = 134465464;
const BSC_CHAIN_ID = 56;

const STREAK_ABI = [
  "function checkIn()",
  "function streak(address) view returns (uint256)",
  "function checkIns(address) view returns (uint256)",
  "function totalUsers() view returns (uint256)",
  "function totalCheckIns() view returns (uint256)",
  "function checkedInToday(address) view returns (bool)",
  "event CheckedIn(address indexed user, uint256 indexed day, uint256 streak, uint256 totalCheckIns)"
];
const ID_ABI = ["function balanceOf(address) view returns (uint256)"];

const $ = (id) => document.getElementById(id);
const provider = new ethers.JsonRpcProvider("https://bsc-dataseed1.binance.org");
const readContract = new ethers.Contract(STREAK_ADDRESS, STREAK_ABI, provider);
const idContract = new ethers.Contract(AGENT_ID, ID_ABI, provider);
const deployed = STREAK_ADDRESS !== "0x0000000000000000000000000000000000000000";

let signer = null;
let userAddr = null;

function short(addr) { return addr.slice(0, 6) + "…" + addr.slice(-4); }

async function refreshGlobal() {
  if (!deployed) { $("totalUsers").textContent = "—"; $("totalCheckins").textContent = "—"; $("recent").innerHTML = "<li>Contract not deployed yet.</li>"; return; }
  try {
    const [users, total] = await Promise.all([readContract.totalUsers(), readContract.totalCheckIns()]);
    $("totalUsers").textContent = users.toString();
    $("totalCheckins").textContent = total.toString();
    const events = await readContract.queryFilter(readContract.filters.CheckedIn(), DEPLOY_BLOCK);
    const last = events.slice(-10).reverse();
    $("recent").innerHTML = last.length === 0
      ? "<li>No check-ins yet — be the first.</li>"
      : last.map((e) => `<li>${short(e.args.user)} — streak ${e.args.streak} (day ${e.args.day})</li>`).join("");
  } catch (err) { $("recent").innerHTML = "<li>Could not load on-chain data.</li>"; }
}

async function refreshUser() {
  if (!userAddr || !deployed) return;
  try {
    const [hasId, streak, mine, done] = await Promise.all([
      idContract.balanceOf(userAddr),
      readContract.streak(userAddr),
      readContract.checkIns(userAddr),
      readContract.checkedInToday(userAddr)
    ]);
    $("hasId").textContent = hasId > 0n ? "Yes ✓" : "No — claim one in the Binance app first";
    $("streak").textContent = streak.toString();
    $("myTotal").textContent = mine.toString();
    const btn = $("checkinBtn");
    btn.disabled = !(hasId > 0n) || done;
    btn.textContent = done ? "Already checked in today ✓" : "Check in today";
  } catch (err) { $("status").textContent = "Could not read your status: " + err.message; }
}

$("connectBtn").addEventListener("click", async () => {
  if (!window.ethereum) { $("status").textContent = "No wallet found. Install MetaMask, OKX Wallet, or the Binance Wallet extension."; return; }
  try {
    const web3 = new ethers.BrowserProvider(window.ethereum);
    const net = await web3.getNetwork();
    if (Number(net.chainId) !== BSC_CHAIN_ID) {
      try {
        await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x38" }] });
      } catch (e) {
        await window.ethereum.request({ method: "wallet_addEthereumChain", params: [{
          chainId: "0x38", chainName: "BNB Smart Chain",
          rpcUrls: ["https://bsc-dataseed1.binance.org"],
          nativeCurrency: { name: "BNB", symbol: "BNB", decimals: 18 },
          blockExplorerUrls: ["https://bscscan.com"]
        }] });
      }
    }
    signer = await web3.getSigner();
    userAddr = await signer.getAddress();
    $("addr").textContent = userAddr;
    $("account").style.display = "block";
    $("status").textContent = "Connected.";
    $("connectBtn").textContent = "Connected: " + short(userAddr);
    await refreshUser();
  } catch (err) { $("status").textContent = "Connection failed: " + err.message; }
});

$("checkinBtn").addEventListener("click", async () => {
  if (!signer) return;
  const btn = $("checkinBtn");
  btn.disabled = true;
  $("status").textContent = "Confirm the check-in in your wallet…";
  try {
    const c = new ethers.Contract(STREAK_ADDRESS, STREAK_ABI, signer);
    const tx = await c.checkIn();
    $("status").textContent = "Transaction sent: " + tx.hash + " — waiting for confirmation…";
    await tx.wait();
    $("status").textContent = "Checked in! 🔥";
    await refreshUser();
    await refreshGlobal();
  } catch (err) {
    $("status").textContent = "Check-in failed: " + (err.reason || err.message);
    btn.disabled = false;
  }
});

$("contractAddr").textContent = deployed ? STREAK_ADDRESS : "deploying soon";
refreshGlobal();
