# /ˈsæːdoʊ/ (Signed Application Do)

Sado is an application designed to _securely_ and _programmatically_ grant TCC permissions to macOS executables in launchd and interactive contexts.

## Examples
If `$sado` is the location of the Sado executable (e.g. `$sado=/Applications/Sado.app/Contents/MacOS/Sado`)

```sh
# If you don't have a sado profile installed by your administrator,
# you can change your list of allowable commands for testing.
# A sado command must have a name, the full path of an executable and arguments.
$ $sado add-command my_echo /bin/echo test
$ $sado add-command my_true /usr/bin/true
$ $sado list-commands
Available commands:
my_true: ["/usr/bin/true"]
my_echo: ["/bin/echo", "test"]

# Now, we can run one of these commands with sado:
$ $sado run /bin/echo test
test

# But a command without exactly matching arguments is not runnable
$ $sado run /bin/echo hello there!
["/bin/echo", "hello", "there!"] not in a valid command

# You may also run a command by giving its name
$ $sado run-by-name my_true

# Clearing the list is trivial if it is not admin-enforced
$ $sado clear-commands
$ $sado list-commands
No available commands.

# And sado will "fail open" if has been given no configuration.
$ $sado run /bin/echo "I'm a bad command!"
I'm a bad command!
```

## Requirements
Sado requires macOS 11.0 or later.

## Building Sado
Sado can be built in Xcode, or in the terminal using `xcodebuild`.

To build Sado.app, run
```sh
$ xcodebuild -project 'Sado.xcodeproj' -scheme 'Sado'
```
and to build the Sado binary, to test; run
```sh
$ xcodebuild -project 'Sado.xcodeproj' -scheme 'SadoBinary'
```

## Why Sado?
See the page on [Technical Details](docs/technical_details.md) for more information on how Sado works, how to use it and similar software.

## Discussions and support
Sado can be discussed on the [MacAdmin](https://www.macadmins.org/) slack in the [#meta-open-source](https://macadmins.slack.com/archives/C05KU2YA17U) channel.

See the [CONTRIBUTING](docs/CONTRIBUTING.md) docs if you would like to help out.

## License
Sado is Apache-2.0 licensed, as found in the [LICENSE](./LICENSE) file.
