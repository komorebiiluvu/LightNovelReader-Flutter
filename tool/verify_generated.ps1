$ErrorActionPreference = 'Stop'
function Invoke-Checked([string[]] $Arguments) {
  & dart @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Dart generation/check command failed ($LASTEXITCODE)." }
}

# Supported build_runner 2.16.1 mode; avoids a Windows AOT temporary-path issue.
Invoke-Checked @('run', 'build_runner', 'clean')
Invoke-Checked @('run', 'build_runner', 'build', '--force-jit')
Invoke-Checked @('run', 'drift_dev', 'schema', 'dump', 'lib/src/data/persistence/database.dart', 'drift_schemas/')
Invoke-Checked @('run', 'drift_dev', 'schema', 'generate', 'drift_schemas/', 'test/persistence/generated/')
Invoke-Checked @('format', 'lib/src/data/persistence/database.g.dart', 'test/persistence/generated/')

$generatedPaths = @('lib/src/data/persistence/database.g.dart', 'drift_schemas/', 'test/persistence/generated/')
git diff --exit-code -- @generatedPaths
if ($LASTEXITCODE -ne 0) { throw 'Committed Drift outputs are stale.' }
$untracked = git ls-files --others --exclude-standard -- @generatedPaths
if ($LASTEXITCODE -ne 0 -or $untracked) { throw 'Generated outputs are not committed.' }
