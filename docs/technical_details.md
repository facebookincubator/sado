## The responsible process

Sado exists in order to grant—or modify how permissions are granted—to macOS executables. Permissions are granted in macOS based on the responsible process. Which process is deemed 'responsible' may be highly unintuitive, and QT has written a [blog post][responsible process] about how this works.

For example, lets say that a daemon should be running on a macOS device with full-disk-access. launchd could have been configured to execute the following bash script, for better failure behaviour:
```bash
#!/bin/bash
if `#should we run the daemon?`; then
  /path/to/my/management_service
else
  printf "oh no! We can't run the daemon" > $errorfile
fi
```
In this case, the responsible process for actions taken by the management service is neither the management service nor the script. It is /bin/bash!
Furthermore, management permissions should not be granted to bash due to security implications (anybody could create a LaunchDaemon with a bash script, and take advantage of these permissions).

Sado lets you solve this in the following ways

### Run a LaunchDaemon using Sado

If you create a LaunchDaemon with Sado as the first program, then Sado will become the responsible process. For example, your LaunchDaemon should look like
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/Sado</string>
        <string>run</string>
        <string>/path/to/daemon</string>
    </array>
</dict>
</plist>
```
As Sado is responsible, TCC permissions should be granted directly to Sado.

### Use `--claim` to set responsibility at any point

If you are not operating in a launchd context, or need to set responsibility in multiple environments (e.g. LaunchDaemon and terminal context) in a consistent manner, Sado provides the `--claim` flag to gain responsibility at any point.

For example, the bash script example before may be changed to
```bash
sado run --claim /path/to/my/management_service
```
In this case, `management_service` will run with Sado's permissions no matter how it is run.


### Use `disclaim` to set the responsible process

If your executable is signed, and already has TCC permissions, but it is difficult to make it the responsible process (due to a complex supervision tree, or it is run in different contexts) you may use the `disclaim` flag to make it the responsible process at any point.

For example, the bash script example before may be changed to
```bash
sado disclaim /path/to/my/management_service
```
In this case, `management_service` will run with its own permissions. Be aware, `sado disclaim` will run any commands, as there is no escalation or deescalation of privileges.


### How `claim` and `disclaim` work
Sado is able to change the responsible process using the `responsibility_spawnattrs_setdisclaim()` function documented in the [curious case][responsible process] blog post. That function modifies `posix_spawn()` to notify the OS that the spawned process is responsible for itself. This API is primarily used to spawn GUI applications from the terminal, such as XCode; as these applications often require special permissions that are not present in a terminal context.

`sado run --claim` forks & disclaims itself, and then continues to spawn the desired process—effectively granting that process its own permissions. `sado disclaim` adds the disclaim flag when spawning the desired child. `sado run` or `run-by-name` without the `--claim` flag is just a signed process that can (via configured policy) exec other things, and doesn't use the "disclaim" API.

## Feature comparison

Sado is similar in nature to [munkishim][munkishim] in the munki project and [disclaim][qt-disclaim] in Qt Creator. However, munkishim is only allowed to execute munki, and disclaim may run any executable.

Sado attempts to perform the same tasks (and more) while being configurable in a secure way (by MDM).

[responsible process]: https://www.qt.io/blog/the-curious-case-of-the-responsible-process
[munkishim]: https://github.com/munki/munki/blob/main/code/apps/munkishim/munkishim/main.m
[qt-disclaim]: https://github.com/qt-creator/qt-creator/blob/master/src/tools/disclaim/disclaim.mm
