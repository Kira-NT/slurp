#!/bin/sh
#
# Slurp an executable and its satellite files into a single binary.

#################################################
# Prints version information.
# Arguments:
#   None
# Outputs:
#   Writes version information to stdout.
#################################################
version() {
  echo "slurp 1.1.0"
}

#################################################
# Prints a brief help message.
# Arguments:
#   None
# Outputs:
#   Writes the help message to stdout.
#################################################
help() {
  echo "Usage: ${0} [-r <executable>] [-o <output-file>] [--] <input-directory>"
  echo "       ${0} --unpack [-o <output-directory>] [--] <input-file>"
  echo
  echo "Slurp an executable and its satellite files into a single binary."
  echo
  echo "Examples:"
  echo "  ${0} ./bin/ --run ./bin/autorun.sh --output ./app"
  echo "  ${0} ./bin/ --output ./app"
  echo "  ${0} ./bin/"
  echo "  ${0} ./app --unpack --output ./app.slurp/"
  echo "  ${0} ./app --unpack"
  echo
  echo "Arguments:"
  echo "  <input-directory>"
  echo "      The directory containing the files and subdirectories to be slurped."
  echo
  echo "  <input-file>"
  echo "      The binary file to be unslurped."
  echo
  echo "Options:"
  echo "  -h, --help"
  echo "      Displays this help page."
  echo
  echo "  -v, --version"
  echo "      Displays the application version."
  echo
  echo "  -r, --run <executable>"
  echo "      Specifies the primary executable file within the input directory."
  echo "      If omitted, slurp will attempt to locate one by searching for it in the following order:"
  echo "        1. An executable named \"autorun\""
  echo "        2. An executable named \"autorun.sh\""
  echo "        3. A sole executable file in the root of the input directory"
  echo "           (if the search yields zero or multiple results, no match is made)."
  echo
  echo "  -o, --output <output-file>"
  echo "      Specifies the name of the resulting binary."
  echo "      If omitted, the binary name is derived automatically from the main executable:"
  echo "        - The main executable's basename is used, unless it is \"autorun\"."
  echo "        - If the main executable's basename is \"autorun\", the name of the input directory is used."
  echo "        - A numeric suffix (e.g., \".1\", \".2\", etc.) is appended if the chosen filename is already in use."
  echo
  echo "  -o, --output <output-directory>"
  echo "      Specifies the name of the output directory."
  echo "      If omitted, defaults to \"<input-file>.slurp\"."
  echo
  echo "  -u, --unpack, --unslurp"
  echo "      Unpack a binary created by slurp."
}

#################################################
# Formats and prints the provided error message.
# Arguments:
#   $1. The error message to format and print.
# Outputs:
#   Writes the formatted error message to stderr.
# Returns:
#   Always returns 1.
#################################################
error() {
  echo "${0}: ${1}" >& 2
  return 1
}

#################################################
# Formats and prints the provided error message,
# displays the help page, and terminates the
# process.
# Arguments:
#   $1. The error message to format and print.
# Outputs:
#   Writes the formatted error message to stderr.
# Returns:
#   Never returns (exits with a status of 1).
#################################################
fatal_error() {
  error "${1}"
  help >& 2
  exit 1
}

#################################################
# Finds a single executable file
# in the provided directory.
# Arguments:
#   $1. The directory to search in.
# Outputs:
#   Writes the path to the executable file,
#   if exactly one is found, to stdout.
# Returns:
#   0 if exactly one executable file is found;
#   otherwise, a non-zero status.
#################################################
find_single_executable() {
  local exec_filename=$(find "${1}" -maxdepth 1 -type f -executable -exec file {} + | grep -iE ":.+executable" | cut -d: -f1)
  [ -n "${exec_filename}" ] && [ $(echo "${exec_filename}" | wc -l) -eq 1 ] && echo "${exec_filename}"
}

#################################################
# Determines the default executable file
# in the provided directory.
# Arguments:
#   $1. The directory to search in.
# Outputs:
#   Writes the path to the executable file,
#   if found, to stdout.
# Returns:
#   0 if a default executable is found;
#   otherwise, a non-zero status.
#################################################
find_default_executable() {
  local default_exec_filename=""
  if [ -f "${1}/autorun" ] && [ -x "${1}/autorun" ]; then
    default_exec_filename="${1}/autorun"
  elif [ -f "${1}/autorun.sh" ] && [ -x "${1}/autorun.sh" ]; then
    default_exec_filename="${1}/autorun.sh"
  else
    default_exec_filename=$(find_single_executable "${1}")
  fi
  [ -n "${default_exec_filename}" ] && echo "${default_exec_filename}"
}

#################################################
# Determines the default output filename based on
# the input directory and the executable file.
# Arguments:
#   $1. The input directory.
#   $2. The main executable file.
# Outputs:
#   Writes the output filename to stdout.
# Returns:
#   Always returns 0.
#################################################
get_default_output_filename() {
  local input_dirname="${1}"
  local exec_filename="${2}"
  local output_filename="$(basename "${exec_filename}" ".sh")"
  [ "${output_filename}" = "autorun" ] && output_filename="$(basename "$(realpath -m "${input_dirname}")")"

  if [ -e "${output_filename}" ]; then
    output_filename_suffix=1
    while [ -e "${output_filename}.${output_filename_suffix}" ]; do
      output_filename_suffix=$((${output_filename_suffix} + 1))
    done
    output_filename="${output_filename}.${output_filename_suffix}"
  fi

  echo "${output_filename}"
}

#################################################
# Creates a preamble for a self-extracting
# executable archive.
# Arguments:
#   $1. The path of the main script.
#   $2. The byte size of the resulting preamble.
# Outputs:
#   Writes the preamble script to stdout.
#################################################
create_preamble() {
  local exec_filename="${1}"
  local byte_count=${2:-"$(create_preamble "${exec_filename}" 0 | wc -c)"}
  local archive_start=$((${byte_count} + 1))
  [ -z "${2}" ] && archive_start=$((${archive_start} + ${#archive_start} - 1))

  echo '#!/bin/sh'
  echo '#?slurp'
  echo 'TEMP_DIR=$(mktemp -d)'
  echo 'trap '\''rm -rf "$TEMP_DIR"; trap - EXIT; exit'\'' EXIT INT HUP'
  echo 'tail -c +'${archive_start}' "$0" | tar -xzC "$TEMP_DIR" && "$TEMP_DIR/'"${exec_filename}"'" "$@"'
  echo 'exit'
}

#################################################
# Packages a directory into a self-extracting
# executable archive.
# Arguments:
#   $1. The input directory.
#   $2. The main executable file.
# Outputs:
#   Writes the resulting archive to stdout.
# Returns:
#   0 if the operation succeeds;
#   otherwise, a non-zero status.
#################################################
pack() {
  create_preamble "${2}"
  tar -czf - -C "${1}" .
}

#################################################
# Packages a directory into a self-extracting
# executable archive and saves it as a file.
# Arguments:
#   $1. The input directory.
#   $2. The output filename (optional).
#   $3. The main executable file (optional).
# Outputs:
#   If output filename is '-', writes
#   the resulting archive to stdout.
# Returns:
#   0 if the operation succeeds;
#   otherwise, a non-zero status.
#################################################
pack_into_file() {
  local input_dirname="${1}"
  [ -n "${input_dirname}" ] || error "missing operand" || return

  local exec_filename=$(realpath -s --relative-to="${input_dirname}" "${3:-"$(find_default_executable "${1}")"}" 2> /dev/null)
  [ -n "${exec_filename}" ] || error "missing file operand" || return
  echo "${exec_filename}" | grep -qvE '^(\.\.|/)' || error "invalid file operand: '${3}' points outside of '${1}'" || return

  local output_filename="${2:-"$(get_default_output_filename "${input_dirname}" "${exec_filename}")"}"
  if [ "${output_filename}" = "-" ]; then
    pack "${input_dirname}" "${exec_filename}"
  else
    pack "${input_dirname}" "${exec_filename}" > "${output_filename}" &&
    chmod a+x "${output_filename}"
  fi
}

#################################################
# Checks if a file is a valid slurp binary.
# Arguments:
#   $1. The file to check.
# Returns:
#   0 if the file is a valid slurp binary;
#   otherwise, a non-zero status.
#################################################
is_slurp_file() {
  local expected_header="#!/bin/sh #?slurp"
  local header=$(head -c "$(printf '%s' "${expected_header}" | wc -c)" "${1}" 2> /dev/null | sed 'N;s/\n/ /')
  [ "${header}" = "${expected_header}" ]
}

#################################################
# Extracts contents of a slurp binary
# into a directory.
# Arguments:
#   $1. The input file.
#   $2. The output directory (optional).
# Returns:
#   0 if the operation succeeds;
#   otherwise, a non-zero status.
#################################################
unpack() {
  local input_filename="${1}"
  [ -e "${input_filename}" ] || error "${input_filename}: Cannot open: No such file or directory" || return
  is_slurp_file "${input_filename}" || error "${input_filename}: Is not a file produced by slurp" || return

  local output_dirname="${2:-"$(basename "${input_filename}").slurp"}"
  [ -d "${output_dirname}" ] || mkdir "${output_dirname}" || return

  sed '1,/^exit$/ d' "${input_filename}" | tar -xzC "${output_dirname}"
}

#################################################
# The main entry point for the script.
# Arguments:
#   ... A list of the command line arguments.
# Returns:
#   0 if the operation succeeds;
#   otherwise, a non-zero status.
#################################################
main() {
  local input=""
  local output=""
  local exec_filename=""
  local command="pack_into_file"

  # Parse the arguments and options.
  while [ $# -gt 0 ]; do
    case "${1}" in
      -h|--help) help; exit 0 ;;
      -v|--version) version; exit 0 ;;
      -r|--run) exec_filename="${2}"; shift ;;
      -o|--output) output="${2}"; shift ;;
      -u|--unpack|--unslurp) command="unpack" ;;
      --) shift; break ;;
      -*) fatal_error "invalid option: '${1}'" ;;
      *) [ -z "${input}" ] && input="${1}" || fatal_error "invalid argument: '${1}'" ;;
    esac
    shift 2> /dev/null || fatal_error "missing operand"
  done
  while [ $# -gt 0 ]; do
    [ -z "${input}" ] && input="${1}" || fatal_error "invalid argument: '${1}'"
    shift
  done

  "${command}" "${input}" "${output}" "${exec_filename}"
}

main "${@}"
