const output = document.getElementById("output");
const button = document.getElementById("load");
const placeholderUrl = "https://api.${KANYE_API_KEY}.rest/";
const expectedUrl = placeholderUrl.replace("${KANYE_API_KEY}", "kanye");

button.onclick = async () => {
  output.textContent = `Input URL (with placeholder):\n${placeholderUrl}\n\nExpected URL sent by proxy:\n${expectedUrl}\n\nLoading…`;
  try {
    const response = await fetch(
      `/api/proxy?url=${encodeURIComponent(placeholderUrl)}`
    );
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const text = await response.text();
    let content;
    try {
      const json = JSON.parse(text);
      content = JSON.stringify(json, null, 2);
    } catch (_) {
      content = text;
    }
    output.textContent = 
      `Input URL (with placeholder):\n${placeholderUrl}\n\n` +
      `Expected URL sent by proxy:\n${expectedUrl}\n\n` +
      `Response:\n${content}\n\n` +
      `Thank you Kanye for the wisdom! It truly makes you think.`;

  } catch (err) {
    output.textContent = 
      `Input URL (with placeholder):\n${placeholderUrl}\n\n` +
      `Expected URL sent by proxy:\n${expectedUrl}\n\n` +
      `Error:\n${err.toString()}`;
  }
};