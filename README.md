# slurp

[![Version](https://img.shields.io/github/v/release/Kira-NT/slurp?sort=date&label=version)](https://github.com/Kira-NT/slurp/releases/latest)
[![License](https://img.shields.io/github/license/Kira-NT/slurp?cacheSeconds=36000)](LICENSE.md)

`slurp` is a simple tool that can help you pack an executable along with its satellite files *(such as libraries, configuration files, etc.)* into a single binary.

----

## Installation

`slurp` does not require installation in the traditional sense, since it's just a standalone shell script. Therefore, you have several options for integrating it into your system:

 - **Direct Download:** <br>
   Download the `slurp` file from the [latest release](https://github.com/Kira-NT/slurp/releases/latest), place it in a directory that is in your system's `PATH`, grant it executable permissions, and run it:
   ```sh
   chmod +x slurp
   slurp <input-directory> [options]
   ```

 - **Clone and Run:** <br>
   Clone the repository and run `slurp.sh` directly from the working tree:
   ```sh
   git clone https://github.com/Kira-NT/slurp
   cd slurp
   ./slurp.sh <input-directory> [options]
   ```

 - **Run Without Saving:** <br>
   If you only need `slurp` for a single task, you can run it without permanently saving the script by using the following snippet:
   ```sh
   curl -Ls https://github.com/Kira-NT/slurp/blob/HEAD/slurp.sh?raw=true | bash -s -- <input-directory> [options]
   ```

Note, `slurp` and the binaries it produces depend on [GNU `coreutils`](https://www.gnu.org/software/coreutils/). Hence, it will only work on macOS, FreeBSD, and other Unix-like systems outside of the Linux ecosystem if `coreutils` have been manually installed there by the user.

----

## Usage

```
Usage: slurp [-r <executable>] [-o <output-file>] [--] <input-directory>
       slurp --unpack [-o <output-directory>] [--] <input-file>

Slurp an executable and its satellite files into a single binary.

Examples:
  slurp ./bin/ --run ./bin/autorun.sh --output ./app
  slurp ./bin/ --output ./app
  slurp ./bin/
  slurp ./app --unpack --output ./app.slurp/
  slurp ./app --unpack

Arguments:
  <input-directory>
      The directory containing the files and subdirectories to be slurped.

  <input-file>
      The binary file to be unslurped.

Options:
  -h, --help
      Displays this help page.

  -v, --version
      Displays the application version.

  -r, --run <executable>
      Specifies the primary executable file within the input directory.
      If omitted, slurp will attempt to locate one by searching for it in the following order:
        1. An executable named "autorun"
        2. An executable named "autorun.sh"
        3. A sole executable file in the root of the input directory
           (if the search yields zero or multiple results, no match is made).

  -o, --output <output-file>
      Specifies the name of the resulting binary.
      If omitted, the binary name is derived automatically from the main executable:
        - The main executable's basename is used, unless it is "autorun".
        - If the main executable's basename is "autorun", the name of the input directory is used.
        - A numeric suffix (e.g., ".1", ".2", etc.) is appended if the chosen filename is already in use.

  -o, --output <output-directory>
      Specifies the name of the output directory.
      If omitted, defaults to "<input-file>.slurp".

  -u, --unpack, --unslurp
      Unpack a binary created by slurp.
```

----

## License

Licensed under the terms of the [MIT License](LICENSE.md).
