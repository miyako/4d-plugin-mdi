![version](https://img.shields.io/badge/version-16%2B-8331AE)
![platform](https://img.shields.io/static/v1?label=platform&message=win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-mdi)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-mdi/total)

# 4d-plugin-mdi

A 4D plugin that controls the main **MDI window** (the frame that contains all your forms and windows when the application runs in MDI mode on Windows). It drives the native Windows window functions on that frame to read and change its title, icon, size, position, and z-order, to maximize/minimize/restore it, and to enable or disable its close box. Text values are returned as `Text` and numeric values as `Longint`.

| Command | Returns | Purpose |
|---|---|---|
| [MDI Get title](#mdi-get-title) | `Text` | Read the MDI window's title |
| [MDI SET TITLE](#mdi-set-title) | — | Change the MDI window's title |
| [MDI USE ICON FILE](#mdi-use-icon-file) | — | Replace the MDI window's icon with a `.ico` file |
| [MDI MAXIMIZE](#mdi-maximize) | — | Maximize the MDI window |
| [MDI MINIMIZE](#mdi-minimize) | — | Minimize the MDI window |
| [MDI RESTORE](#mdi-restore) | — | Restore the MDI window from maximized/minimized |
| [MDI SET CLOSE BOX ENABLED](#mdi-set-close-box-enabled) | — | Enable or disable the window's close box |
| [MDI Get close box enabled](#mdi-get-close-box-enabled) | `Longint` | Read the close box state |
| [MDI SET POSITION](#mdi-set-position) | — | Move, resize, and re-order the MDI window |
| [MDI GET POSITION](#mdi-get-position) | — | Read the MDI window's position and size |

**Platforms:** Windows 64-bit, 4D v16 or later (MDI mode only)

## Manual source versioning and releases

**Bump version** and **Build** are independent manual Actions. Neither runs on
branch pushes, pull requests, or tag pushes. Use GitHub's built-in ref selector;
Build has no custom inputs. Every checkout uses the immutable selected
`github.sha`. Build has one repository-wide `release-publication` concurrency
group, with cancellation disabled, across all selected refs.

Run **Bump version** on a branch and select `patch`, `minor`, or `major`. It
requires a clean checkout at the exact selected remote branch SHA, validates all
metadata before writing, and creates one nonempty source-only direct-child
commit with the Copilot co-author trailer. The executable pre-push hook checks
the server's advertised old SHA/ref, literal new SHA and local HEAD, single
direct parent, and exactly one update (including rejecting an already-pushed
same-result race). The hook must exist and be executable both before preparation
and immediately before push. Push is non-force, with both `push.followTags=false`
and `--no-follow-tags`. A moved branch, missing hook, or failed guard stops the
operation; select the updated branch and dispatch again after inspecting the
failure. Bump creates no tag, release, build, or dispatch.

### Source authority and intake repair

The coordinated source contract covers all **three** assignments each of
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in
`MDI.xcodeproj/project.pbxproj`, required `CFBundleShortVersionString` in
`Info.plist`, optional `CFBundleVersion` only when present, and both display
version fields in `English.lproj/InfoPlist.strings`. All literal versions must
be the same canonical `X.Y.Z`; missing, duplicate, malformed, or drifted fields
are errors. Supported `$(MARKETING_VERSION)`, `${MARKETING_VERSION}`,
`$(CURRENT_PROJECT_VERSION)`, and `${CURRENT_PROJECT_VERSION}` plist references
are preserved. Current-project settings may reference marketing, never
themselves. Unknown or cyclic references fail closed. Rewrites preserve BOM,
individual line endings, modes, references, and unrelated bytes.

History followed through `.github/workflows/bump-version.yml` ends at its
introduction in `690f94a` (the layout move); no predecessor workflow exists in
its parent. Its header explicitly coordinates marketing/current-project and
short/build plist versions. `a3650e7` retains that contract, although its
marketing-first/fallback implementation updates only one project key.
Generated commits `dd2294a` and `ab05517` advanced marketing and the source
plist to **3.0.2**, leaving current-project and source localization at **3.0.0**.
This migration repairs only those proven-stale source fields to existing
authority **3.0.2**; it does not increment the release version, add the absent
`CFBundleVersion`, or change any prebuilt metadata.

Prebuilt `test/Plugins/MDI.bundle` files, destination localization, Windows
binaries, resources, dependencies, `manifest.json`, XLIFF constants, and 4D
data/schema counters are not version authority and are never changed by Bump.
Only the three source metadata paths above are staged by the helper.

### Build and create-only publication

After Bump, manually select the resulting branch/commit in **Build**. An early
authenticated check requires both the exact `vX.Y.Z` remote tag and any release
for it (including drafts) to be absent. Releases are checked page by page through
the final page; authentication, network, HTTP 404, malformed responses, and
later-page failures are errors, never evidence of absence.

The original native pipeline is preserved: Windows `Release|x64` with the
workflow's `v143`/SDK `10.0` overrides of the unchanged `v140` project, then
macOS target `MDI`, configuration `Default`, `arm64 x86_64`, deployment override
`10.13`, `ONLY_ACTIVE_ARCH=NO`, signing disabled during compilation, and output
`test/Plugins`. The project configurations, Cocoa framework, copied resources,
and six existing secret names are unchanged. This packaging topology does not
add macOS implementations to the Windows-only MDI commands.

Windows cleanup invalidates only the exact Release x64 `.4DX` and `Objs`; its
output must be the project's exact
`test/plugins/MDI.bundle/contents/windows64/MDI.4DX`, not a recursive match.
macOS cleanup invalidates only the generated binary, plist, English strings,
signature, and `MDI.build` intermediate. Other bundle contents, Windows outputs,
dependencies, and sibling `Default` resources survive. Cleanup errors are
fatal. Exact `arm64` and `x86_64` tokens are required, without an invented
slice-count or additional-architecture exclusion. Built plist and localized
versions must match the selected source, including normal, XML/binary plist,
and UTF-16 localized representations.

The Windows artifact is merged before Developer ID signing and strict
verification. Both ZIP and DMG notarization commands must succeed **and** return
JSON status `Accepted`; DMG stapling must succeed. Only after all these gates
does the final authenticated tag/release-absence check run again.
Publication then performs separate create-only operations: `POST git/refs` at
the selected SHA, exact remote-tag verification, `POST releases` for a new
public, non-prerelease release with explicit tag/name/target, then individual
asset POSTs to the newly returned release ID. Original empty release notes
remain empty. Existing tags/releases are never reused, edited, deleted, or
overwritten; there is no combined create-and-upload command, retry, or rollback.

### Partial-publication recovery

Any created tag, release, and successfully uploaded assets are retained if a
later step fails, including an ambiguous transport failure. Inspect the Actions
error, exact tag SHA, draft/public releases, returned release ID, and asset list
before deciding what to do. Do not rerun Build expecting it to complete or
replace existing state: its absence checks intentionally reject that version.
An authorized maintainer must investigate retained state and choose recovery
outside this create-only automation, or use Bump and build a new version.
Never move/delete a tag or clobber assets as an automatic repair.

### Offline verification

Run `actionlint .github/workflows/*.yml` and
`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .github/tests -v`.
PowerShell (`pwsh`) is required to exercise the Windows shell tests rather than
skip them. The suite derives fixtures from the current source, exercises real
local Git/bare-origin guarded pushes and advertisement races, and extracts
literal workflow shell/PowerShell blocks with closed-PATH native stubs. It
does not run native compilers, signing, notarization, 4D, or GitHub publication.
Run the full suite again in a disposable clone after a genuine helper-driven
guarded source bump; verify clean equal local/remote heads, a source-only direct
parent, required trailer, and no remote tags, then remove the fixture.

---

## Requirements & platform notes

- **Windows only.** The source contains no macOS implementation: every command body is compiled for Windows only. If the plugin is loaded on macOS at all, commands do nothing, `MDI Get title` returns an empty text, `MDI Get close box enabled` returns `0`, and `MDI GET POSITION` returns `0` in all four variables.
- **4D v16 or later.** The plugin locates the MDI window through the 4D main-window handle on v16+. The source also contains a fallback lookup for older versions (matching a window class against the application folder path), but the README lists v16+ as the supported range.
- **Manifest location.** The README says that for older versions you must move `manifest.json` into `Contents`. It words this as "v17 and earlier" in one place and "v16 or v17" in another; follow it for the version you actually deploy on.
- **MDI mode only.** If the application runs in SDI mode (no MDI frame), every command is skipped silently. The plugin detects this by calling `GET WINDOW RECT` for a window reference of `-1`; an all-zero rectangle is taken to mean "no MDI window". The same heuristic would also match any other situation where that call returns zeros (for example a context with no user interface), so treat "nothing happened" as a possible sign of this check.
- **Failure is silent.** No command raises a 4D error or sets `OK`. A missing window, a bad icon path, or a rejected window operation all end in "nothing happened". Read values back (`MDI GET POSITION`, `MDI Get title`) if you need to confirm a change took effect.
- **SDI-mode results are not reliable.** In SDI mode `MDI Get title` and `MDI Get close box enabled` are not computed by the plugin, so don't rely on their return values; `MDI GET POSITION` leaves your four variables unchanged. Initialize your variables before calling, and don't use these commands in SDI builds.
- **Parameters are mandatory.** Each command reads its parameters unconditionally; there are no optional forms. Pass every parameter listed.
- **Constants.** `MDI SET POSITION` uses the Windows `SetWindowPos` constants. The README lists these names and values (the plugin's own test method uses `HWND_TOP` and `SWP_NOACTIVATE` unquoted):

| `HWND_*` constant | Value | | `SWP_*` constant | Value |
|---|---|---|---|---|
| `HWND_BOTTOM` | 1 | | `SWP_NOSIZE` | 1 |
| `HWND_NOTOPMOST` | -2 | | `SWP_NOMOVE` | 2 |
| `HWND_TOP` | 0 | | `SWP_NOZORDER` | 4 |
| `HWND_TOPMOST` | -1 | | `SWP_NOREDRAW` | 8 |
| | | | `SWP_NOACTIVATE` | 16 |
| | | | `SWP_DRAWFRAME` | 32 |
| | | | `SWP_SHOWWINDOW` | 64 |
| | | | `SWP_HIDEWINDOW` | 128 |
| | | | `SWP_NOCOPYBITS` | 256 |
| | | | `SWP_NOOWNERZORDER` | 512 |
| | | | `SWP_NOSENDCHANGING` | 1024 |
| | | | `SWP_DEFERERASE` | 8192 |
| | | | `SWP_ASYNCWINDOWPOS` | 16384 |

  Combine `SWP_*` flags by adding their values (or with `|`). See Microsoft's `SetWindowPos` documentation for the exact meaning of each flag.
- **Source revision note.** Two behaviors described below (the icon size in `MDI USE ICON FILE`, and the handling of an unknown window reference in `MDI SET POSITION`) reflect the revised source, not the originally published build. They apply once you build from the revised source; a binary you already have installed behaves as described in the "earlier builds" remarks.

---

## MDI Get title

### Syntax

```4d
MDI Get title → Text
```

| Parameter | Type | Description |
|---|---|---|
| Result | `Text` | The current title of the MDI window |

### Description

Returns the text currently shown in the MDI window's title bar. If the title is empty, or the MDI window can't be found, the result is an empty text.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
MDI SET TITLE ("abcde")
$title:=MDI Get title
```

Read the title before changing it, so you can put it back later:

```4d
$originalTitle:=MDI Get title
MDI SET TITLE ("Maintenance mode")
  //... later
MDI SET TITLE ($originalTitle)
```

---

## MDI SET TITLE

### Syntax

```4d
MDI SET TITLE ( title )
```

| Parameter | Type | Description |
|---|---|---|
| `title` | `Text` | The new title for the MDI window |

### Description

Replaces the MDI window's title-bar text. Nothing is returned, and nothing happens if the MDI window can't be found. Text is passed to Windows as Unicode, so non-ASCII characters are supported.

I could not determine from the source whether 4D itself rewrites the title later (for example when switching databases or windows); use `MDI Get title` to check on your build.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
MDI SET TITLE ("abcde")
```

Include live information in the title:

```4d
MDI SET TITLE ("Orders - "+String(Current date))
```

---

## MDI USE ICON FILE

### Syntax

```4d
MDI USE ICON FILE ( iconPath )
```

| Parameter | Type | Description |
|---|---|---|
| `iconPath` | `Text` | Full Windows path to an `.ico` file |

### Description

Loads an icon from disk and sets it as the MDI window's small icon (the one in the title bar).

- The path is handed to Windows as-is, with no conversion. Use a Windows system path such as `C:\Icons\app.ico`, not a POSIX path. (This is inferred from the code, which passes the text straight to the Windows image loader.)
- The file must be a valid `.ico` file. If the file is missing, unreadable, or not an icon, nothing happens and the current icon stays.
- Loading is synchronous on the main process; a path on a slow or unavailable network share can pause the interface until Windows gives up.
- **Revised source:** the icon is loaded at the system's small-icon size, and each call releases the icon the previous call installed. **Earlier builds** loaded the larger default size and scaled it down, and did not release previously installed icons, so calling this command repeatedly in a loop consumed a Windows GDI handle each time.
- When 4D quits, the plugin automatically restores the application's own icon (see [Error handling & troubleshooting](#error-handling--troubleshooting)).

### Example

No sample for this command ships with the plugin, so this one is illustrative:

```4d
MDI USE ICON FILE ("C:\\MyApp\\resources\\app.ico")
```

Guard against a missing file with a document-existence check of your choice before calling, since the command itself gives no feedback:

```4d
$icon:="C:\\MyApp\\resources\\app.ico"
If (Test path name($icon)=Is a document)
	MDI USE ICON FILE ($icon)
End if
```

---

## MDI MAXIMIZE

### Syntax

```4d
MDI MAXIMIZE
```

*No parameters.*

### Description

Maximizes the MDI window. Does nothing if it is already maximized or if the MDI window can't be found.

### Example

From the plugin's own test method (`TEST.4dm`, where it is commented out):

```4d
  //MDI MAXIMIZE
```

Active version:

```4d
MDI MAXIMIZE
```

---

## MDI MINIMIZE

### Syntax

```4d
MDI MINIMIZE
```

*No parameters.*

### Description

Minimizes the MDI window to the taskbar. Use [MDI RESTORE](#mdi-restore) to bring it back. While minimized, [MDI GET POSITION](#mdi-get-position) reports an off-screen position (see that command).

### Example

From the plugin's own test method (`TEST.4dm`, where it is commented out):

```4d
  //MDI MINIMIZE
```

Minimize for a few seconds, then restore (`DELAY PROCESS` is used the same way in the README):

```4d
MDI MINIMIZE
DELAY PROCESS (Current process;60*3)
MDI RESTORE
```

---

## MDI RESTORE

### Syntax

```4d
MDI RESTORE
```

*No parameters.*

### Description

Restores the MDI window to its normal (non-maximized, non-minimized) size and position. Does nothing if the window is already normal or can't be found.

### Example

From the plugin's own test method (`TEST.4dm`, where it is commented out):

```4d
  //MDI RESTORE
```

---

## MDI SET CLOSE BOX ENABLED

### Syntax

```4d
MDI SET CLOSE BOX ENABLED ( enabled )
```

| Parameter | Type | Description |
|---|---|---|
| `enabled` | `Longint` | `0` greys out the close box; any non-zero value enables it |

### Description

Enables or greys out the **Close** entry of the MDI window's system menu, which also greys out the close button in the title bar. Use it to stop users from closing the application by that route.

This only controls the window-menu close action. It does not block quitting through your own menus or a `QUIT 4D` call. When 4D quits (and the plugin unloads), the plugin re-enables the close box automatically.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
MDI SET CLOSE BOX ENABLED (0)
```

Disable the close box only while a long operation runs:

```4d
MDI SET CLOSE BOX ENABLED (0)
  //... long-running work
MDI SET CLOSE BOX ENABLED (1)
```

---

## MDI Get close box enabled

### Syntax

```4d
MDI Get close box enabled → Longint
```

| Parameter | Type | Description |
|---|---|---|
| Result | `Longint` | `1` if the close box is enabled, `0` if it is greyed out |

### Description

Returns the current state of the close box. `0` is also returned if the state can't be read (for example when the MDI window has no system menu); the source does not distinguish that case from "disabled".

### Example

From the plugin's own test method (`TEST.4dm`), including its original comment:

```4d
$close:=MDI Get close box enabled   //enabled when closing the structure/project
```

Toggle the state:

```4d
If (MDI Get close box enabled=1)
	MDI SET CLOSE BOX ENABLED (0)
Else 
	MDI SET CLOSE BOX ENABLED (1)
End if 
```

---

## MDI SET POSITION

### Syntax

```4d
MDI SET POSITION ( insertAfter ; x ; y ; width ; height ; flags )
```

| Parameter | Type | Description |
|---|---|---|
| `insertAfter` | `Longint` | Z-order placement: one of `HWND_TOP`, `HWND_BOTTOM`, `HWND_TOPMOST`, `HWND_NOTOPMOST`, or a 4D window reference |
| `x` | `Longint` | Left edge of the window, in screen pixels |
| `y` | `Longint` | Top edge of the window, in screen pixels |
| `width` | `Longint` | Total width of the window, in pixels |
| `height` | `Longint` | Total height of the window, in pixels |
| `flags` | `Longint` | One or more `SWP_*` flags, added together |

### Description

Moves and resizes the MDI window and sets its z-order in a single call. The values are applied through the Windows `SetWindowPos` function.

**Mind the order of the two option parameters.** `insertAfter` (parameter 1) is the **z-order / placement** option and takes `HWND_*` constants. `flags` (parameter 6) is the **positioning flags** option and takes `SWP_*` constants. (The README calls parameter 6 the "z-order" option; in the code it is the flags value, and z-order is parameter 1.)

- `x`, `y`, `width`, and `height` describe the whole window frame, including title bar and borders, in screen coordinates.
- With `SWP_NOMOVE`, `x` and `y` are ignored. With `SWP_NOSIZE`, `width` and `height` are ignored. With `SWP_NOZORDER`, `insertAfter` is ignored. You still have to pass all six parameters.
- `HWND_TOPMOST` keeps the window above all non-topmost windows until you call the command again with `HWND_NOTOPMOST`. It is not cleared automatically.
- **A 4D window reference** is also accepted for `insertAfter`; the plugin converts it to the native window handle. I could not confirm whether Windows honors that placement for windows that are children of the MDI frame, so prefer the `HWND_*` constants.
- **Revised source:** an unknown or invalid window reference makes the call do nothing. **Earlier builds** converted an unknown reference to a null handle, which Windows treats as `HWND_TOP`, so the window was raised instead of the call being ignored.
- The command has no way to report failure to 4D. If Windows rejects the call, the revised source writes a line to the Windows debug output (visible in a tool such as DebugView) and nothing else happens.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
MDI SET POSITION (HWND_TOP;0;0;900;900;SWP_NOACTIVATE)
```

From the README: save the position, move the MDI window to match the current form window for a while, then restore:

```4d
MDI GET POSITION ($x;$y;$width;$height)
GET WINDOW RECT($l;$t;$r;$b;Current form window)
MDI SET POSITION (HWND_TOPMOST;$l;$t;$r-$l;$b-$t;SWP_NOACTIVATE)
DELAY PROCESS(Current process;60*2.5)
MDI SET POSITION (HWND_TOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```

The README example restores with `HWND_TOPMOST`, which leaves the window topmost. To return it to normal stacking, restore with `HWND_NOTOPMOST`:

```4d
MDI SET POSITION (HWND_NOTOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```

Move the window without resizing it (`width` and `height` are ignored):

```4d
MDI SET POSITION (HWND_TOP;100;50;0;0;SWP_NOSIZE+SWP_NOACTIVATE)
```

---

## MDI GET POSITION

### Syntax

```4d
MDI GET POSITION ( x ; y ; width ; height )
```

| Parameter | Type | Description |
|---|---|---|
| `x` | `Longint` | Output: left edge of the window, in screen pixels |
| `y` | `Longint` | Output: top edge of the window, in screen pixels |
| `width` | `Longint` | Output: total width of the window, in pixels |
| `height` | `Longint` | Output: total height of the window, in pixels |

### Description

Writes the MDI window's position and size, including title bar and borders, into four variables. The values use the same screen coordinates as [MDI SET POSITION](#mdi-set-position), so you can save them and pass them straight back.

- If the MDI window can't be found, or the position can't be read, the four variables are written back with the plugin's default value (expected to be `0`; the default is set by the plugin SDK and was not traced here). In SDI mode the command is skipped and your variables are left untouched.
- **Don't save the position while the window is minimized.** Windows reports a minimized window at a far off-screen position (typically around -32000, -32000). Passing those values back to `MDI SET POSITION` would move the window off the screen. Call [MDI RESTORE](#mdi-restore) first.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
MDI GET POSITION ($x;$y;$width;$height)
```

Show the current geometry:

```4d
MDI GET POSITION ($x;$y;$width;$height)
ALERT ("MDI window: "+String($width)+" x "+String($height)+" at "+String($x)+", "+String($y))
```

---

## Worked examples

### Kiosk-style window setup

Set a title and icon, lock the close box, and maximize the window at startup. The plugin re-enables the close box and restores 4D's icon on its own when 4D quits.

```4d
MDI SET TITLE ("Front Desk")
MDI USE ICON FILE ("C:\\MyApp\\resources\\app.ico")
MDI SET CLOSE BOX ENABLED (0)
MDI MAXIMIZE
```

### Temporary geometry change with safe restore

Save, change, and restore the geometry, making sure the window isn't minimized when it's saved:

```4d
MDI RESTORE
MDI GET POSITION ($x;$y;$width;$height)

MDI SET POSITION (HWND_TOP;0;0;1024;768;SWP_NOACTIVATE)
  //... do work in the resized window

MDI SET POSITION (HWND_NOTOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```

---

## Error handling & troubleshooting

- **Nothing happens at all.** The application is probably in SDI mode, or the MDI window couldn't be found. Every command is skipped silently in that case; there is no error and `OK` is not changed.
- **No 4D error is ever raised.** Bad parameters, a missing icon file, or a window operation Windows rejects all fail quietly. Read the value back (`MDI Get title`, `MDI GET POSITION`, `MDI Get close box enabled`) when you need to verify a change.
- **Return values in SDI mode are unreliable.** `MDI Get title` and `MDI Get close box enabled` may not return anything meaningful, and `MDI GET POSITION` leaves your variables as they were. Initialize variables before the call and avoid these commands in SDI builds.
- **The icon doesn't change.** Check that the path is a Windows system path (not POSIX), that the file exists, and that it is a real `.ico` file. A failed load changes nothing and reports nothing.
- **Slow pause on `MDI USE ICON FILE`.** The file is read synchronously on the main process, so a slow or disconnected network path can stall the interface until Windows times out. Use a local path.
- **The window jumped to the top (earlier builds) / nothing happened (revised source).** You passed an unknown 4D window reference as `insertAfter`. Use an `HWND_*` constant, or a valid window reference.
- **`HWND_TOPMOST` stays in effect.** The window remains above all non-topmost windows until you call `MDI SET POSITION` with `HWND_NOTOPMOST`.
- **Window disappeared after restoring a saved position.** The position was saved while the window was minimized, which yields off-screen coordinates. Call `MDI RESTORE` before `MDI GET POSITION`.
- **Options applied to the wrong setting.** `insertAfter` (parameter 1) takes `HWND_*`; `flags` (parameter 6) takes `SWP_*`. Swapping them applies the wrong numbers to the wrong setting.
- **Close box state returns `0` unexpectedly.** `MDI Get close box enabled` also returns `0` when the state can't be read, not only when it is greyed out.
- **Changes at quit.** When the plugin unloads, and only if an MDI command was used during the session, it re-enables the close box and sets the window icon back to 4D's executable icon. Anything you set with `MDI SET CLOSE BOX ENABLED` or `MDI USE ICON FILE` does not persist across launches.
- **Debugging a rejected `MDI SET POSITION`.** In the revised source, a rejected call writes a line to the Windows debug output. Attach a debug-output viewer to the 4D process to see it.

---

## Quick reference

```4d
  // read
$title:=MDI Get title
$closeEnabled:=MDI Get close box enabled
MDI GET POSITION ($x;$y;$width;$height)

  // title and icon
MDI SET TITLE ("My application")
MDI USE ICON FILE ("C:\\MyApp\\app.ico")

  // window state
MDI MAXIMIZE
MDI MINIMIZE
MDI RESTORE

  // close box
MDI SET CLOSE BOX ENABLED (0)
MDI SET CLOSE BOX ENABLED (1)

  // position: insertAfter;x;y;width;height;flags
MDI SET POSITION (HWND_TOP;0;0;900;900;SWP_NOACTIVATE)
MDI SET POSITION (HWND_TOP;100;50;0;0;SWP_NOSIZE+SWP_NOACTIVATE)
MDI SET POSITION (HWND_NOTOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```
