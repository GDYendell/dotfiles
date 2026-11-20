// Runs the pack's PowerShell helpers. Each call must also be allowed by an
// argsRegex in the widget's shellCommands in zpack.json, which repeats this
// path.
import * as zebar from 'https://esm.sh/zebar@3.3.1';

const SCRIPT_DIR = 'C:\\Users\\GaryYendell\\.glzr\\zebar\\gdy\\';

// Returns trimmed stdout; throws with stderr on a non-zero exit.
export async function runPs(script, args = '') {
  const res = await zebar.shellExec('powershell', `-NoProfile -File ${SCRIPT_DIR}${script}.ps1${args ? ` ${args}` : ''}`);
  if (res.code !== 0) throw new Error(res.stderr);
  return res.stdout.trim();
}

export const runPsJson = async (script, args) => JSON.parse(await runPs(script, args));
