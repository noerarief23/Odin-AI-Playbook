---
name: dotnet-upgrade
description: Upgrade a .NET Core solution (any version) to .NET 10; update project files, NuGet packages, deprecated APIs, and pipeline/container references; validate the result with a build and tests.
tags: [dotnet, upgrade, migration, csharp]
version: 1.0.0
---

# .NET Upgrade to .NET 10

## When to use
- A solution targets `netcoreapp*`, `net5.0`, `net6.0`, `net7.0`, `net8.0`, or `net9.0` and needs to move to `net10.0`.
- A developer asks to "upgrade", "migrate", or "modernise" a .NET project.
- CI or runtime-EOL alerts flag an out-of-support target framework.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `solution_path` | ✅ | Path to the `.sln` file or the root folder containing `.csproj` / `.fsproj` / `.vbproj` files |
| `current_tfm` | optional | Current target framework moniker (e.g. `net6.0`); auto-detected if omitted |
| `run_tests` | optional | `true` (default) / `false` — whether to execute the test suite after upgrading |

## Procedure

### 1. Inventory the solution
- List every project file (`*.csproj`, `*.fsproj`, `*.vbproj`) in the solution.
- For each project record: current `<TargetFramework>` (or `<TargetFrameworks>`), SDK style (`Microsoft.NET.Sdk`, `Microsoft.NET.Sdk.Web`, etc.), and project type (library, web app, worker, test, console).
- Note any `global.json` that pins the SDK version.

### 2. Update `global.json`
- If `global.json` exists, set `"version"` to `"10.0.100"` (or the latest .NET 10 SDK patch) and `"rollForward"` to `"latestMinor"`.
- If `global.json` does not exist, create one in the repo root:
  ```json
  {
    "sdk": {
      "version": "10.0.100",
      "rollForward": "latestMinor"
    }
  }
  ```

### 3. Update target framework monikers
- In every project file replace the current TFM with `net10.0`:
  - `<TargetFramework>net6.0</TargetFramework>` → `<TargetFramework>net10.0</TargetFramework>`
  - For multi-targeting (`<TargetFrameworks>`), replace or add `net10.0` as appropriate.
- Remove obsolete compatibility workarounds that were only needed for earlier TFMs (e.g. `<LangVersion>8.0</LangVersion>` if it was a workaround, not an intentional pin).

### 4. Upgrade NuGet packages
- Run `dotnet list package --outdated` (or inspect lock files) to identify stale packages.
- Update Microsoft-published packages that have a `net10.0` compatible release:
  - `Microsoft.AspNetCore.*`
  - `Microsoft.EntityFrameworkCore.*`
  - `Microsoft.Extensions.*`
  - `System.*` packages that have been inbox since .NET 10 (remove them — they are no longer needed as explicit dependencies).
- For third-party packages, check NuGet.org for a release that supports `net10.0`; update `PackageReference` versions accordingly.
- Use `dotnet restore` after edits to verify dependency resolution.

### 5. Fix breaking API changes
Apply the following changes where present in the codebase:

| Area | .NET Core / earlier API | .NET 10 replacement |
|---|---|---|
| HTTP | `HttpContext.Abort()` (sync) | `await httpContext.Response.CompleteAsync()` |
| Auth | `IHostingEnvironment` | `IWebHostEnvironment` |
| Hosting | `WebHost.CreateDefaultBuilder` | `WebApplication.CreateBuilder` (minimal hosting model) |
| JSON | `Newtonsoft.Json` (if used only for basic serialisation) | `System.Text.Json` |
| Nullable | No `#nullable enable` | Enable nullable reference types per project; fix warnings |
| Minimal APIs | N/A (new pattern) | Offer to migrate controller-based endpoints if explicitly asked |
| Blazor | Legacy `@page` routing quirks | Update to latest Blazor routing conventions if applicable |

Scan for usages of APIs removed or obsoleted between the source TFM and .NET 10 using:
```bash
dotnet build 2>&1 | grep -E "(error|warning) CS"
```
Fix each compiler error before proceeding.

### 6. Update runtime/environment references
- **Dockerfiles**: Replace `FROM mcr.microsoft.com/dotnet/aspnet:X.Y` and `FROM mcr.microsoft.com/dotnet/sdk:X.Y` with the .NET 10 image tag (`10.0`), e.g. `FROM mcr.microsoft.com/dotnet/aspnet:10.0`.
- **CI/CD pipelines** (GitHub Actions, Azure Pipelines, GitLab CI):
  - Update `dotnet-version` or `DOTNET_VERSION` to `10.0.x`.
  - Update any `uses: actions/setup-dotnet` steps to specify `dotnet-version: '10.0.x'`.
- **Kubernetes / Helm charts**: Update image tags that reference a .NET runtime version.
- **`.editorconfig` / `Directory.Build.props`**: Update `<LangVersion>` if explicitly set; .NET 10 defaults to C# 13.

### 7. Enable new .NET 10 features (optional but recommended)
- Enable `<Nullable>enable</Nullable>` and `<ImplicitUsings>enable</ImplicitUsings>` in `Directory.Build.props` or each `*.csproj` if not already set.
- Consider adopting `<PublishSingleFile>true</PublishSingleFile>` or Native AOT where applicable.
- Review and remove any `<RuntimeFrameworkVersion>` pins that are no longer needed.

### 8. Build and verify
```bash
dotnet restore
dotnet build --no-restore -warnaserror
```
- Fix any remaining build errors or warnings treated as errors.
- If `run_tests` is `true` (default), run:
  ```bash
  dotnet test --no-build --verbosity normal
  ```
- All tests must pass before the upgrade is considered complete.

### 9. Produce the change summary
Generate a diff-style summary of all modified files and a list of any manual follow-up items.

## Output format

```
## Upgrade summary

**Source TFM:** <detected TFM>
**Target TFM:** net10.0
**Projects upgraded:** <count>

## Files modified
- <path/to/file> — <reason>
- ...

## Package changes
| Package | Old version | New version |
|---|---|---|
| ... | ... | ... |

## Breaking changes addressed
- <description of each API fix>

## Manual follow-up items
- <anything that could not be automated, e.g. third-party packages with no net10.0 release>

## Build result
✅ Build succeeded  /  ❌ Build failed — see errors below

## Test result
✅ All tests passed (<N> tests)  /  ❌ <N> tests failed — see output below
```

## Common pitfalls
- **Do not upgrade all packages blindly** — some third-party packages may not yet support `net10.0`; pin those and add a follow-up item instead of breaking the build.
- **Check for `netstandard2.0` / `netstandard2.1` library projects** — these usually do not need a TFM change but may need NuGet package updates.
- **Minimal hosting model migration is optional** — migrating from `Startup.cs` + `Program.cs` to the minimal hosting model is a separate concern; do it only if explicitly requested.
- **Multi-targeting projects** — when a library multi-targets (e.g. `net6.0;net8.0`), decide whether to drop older TFMs or keep them; do not drop without explicit confirmation.
- **Entity Framework Core migrations** — after upgrading EF Core, run `dotnet ef migrations add PostUpgrade` if any model changes are detected; otherwise existing migrations remain valid.
- **Nullable warnings** — enabling nullable reference types for the first time will generate many warnings; suppress with `<Nullable>warnings</Nullable>` first, then address gradually.

## Examples

### Example 1 — Minimal console app (net6.0 → net10.0)

**Input:**
```
solution_path: ./MyApp
current_tfm: net6.0
```

**Changes made:**
- `MyApp/MyApp.csproj`: `net6.0` → `net10.0`
- `global.json`: created with SDK `10.0.100`
- `Microsoft.Extensions.Hosting` 6.0.1 → 10.0.0

**Output:**
```
## Upgrade summary
Source TFM: net6.0  |  Target TFM: net10.0  |  Projects upgraded: 1
Build result: ✅ Build succeeded
Test result: ✅ All tests passed (12 tests)
```

---

### Example 2 — ASP.NET Core Web API with Docker (net8.0 → net10.0)

**Input:**
```
solution_path: ./OrderService
current_tfm: net8.0
```

**Changes made:**
- All `*.csproj` files: `net8.0` → `net10.0`
- `Dockerfile`: `mcr.microsoft.com/dotnet/aspnet:8.0` → `mcr.microsoft.com/dotnet/aspnet:10.0`
- `Dockerfile`: `mcr.microsoft.com/dotnet/sdk:8.0` → `mcr.microsoft.com/dotnet/sdk:10.0`
- `.github/workflows/ci.yml`: `dotnet-version: '8.0.x'` → `dotnet-version: '10.0.x'`
- `Microsoft.AspNetCore.OpenApi` 8.0.0 → 10.0.0
- `Microsoft.EntityFrameworkCore.SqlServer` 8.0.0 → 10.0.0

**Manual follow-up items:**
- `SomeVendor.Sdk` 3.2.0 has no `net10.0` compatible release; tracked in follow-up ticket.

**Output:**
```
## Upgrade summary
Source TFM: net8.0  |  Target TFM: net10.0  |  Projects upgraded: 4
Build result: ✅ Build succeeded
Test result: ✅ All tests passed (87 tests)
```
