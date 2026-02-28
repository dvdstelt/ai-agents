const { execSync } = require('child_process');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = data?.model?.display_name || 'unknown';
    const used = data?.context_window?.used_percentage;
    const cwd = data?.workspace?.current_dir;

    const parts = [];

    // Git branch
    if (cwd) {
      try {
        const branch = execSync(`git -C "${cwd}" --no-optional-locks symbolic-ref --short HEAD`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
        if (branch) parts.push(`\x1b[36mbranch: ${branch}\x1b[0m`);
      } catch {}
    }

    // Model
    parts.push(`\x1b[35mmodel: ${model}\x1b[0m`);

    // Context usage
    if (used != null) {
      const pct = Math.floor(used);
      const color = pct >= 80 ? '\x1b[31m' : pct >= 50 ? '\x1b[33m' : '\x1b[32m';
      parts.push(`${color}ctx: ${pct}%\x1b[0m`);
    }

    process.stdout.write(parts.join(' | '));
  } catch {
    process.stdout.write('statusline error');
  }
});
