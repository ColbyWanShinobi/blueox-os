#!/usr/bin/env bash
# Build Lua 5.1 alongside Fedora's current Lua, whose binaries remain
# unversioned. Consumers that require the 5.1 bytecode format can use
# lua5.1 and luac5.1 explicitly.
set -Eeuo pipefail

readonly lua_version='5.1.5'
readonly lua_archive="lua-${lua_version}.tar.gz"
readonly lua_url="https://www.lua.org/ftp/${lua_archive}"
readonly lua_sha256='2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333'
build_dir="$(mktemp -d)"
readonly build_dir

cleanup() {
  rm -rf -- "$build_dir"
}
trap cleanup EXIT

for command in curl make sha256sum tar; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "${command} is required to build Lua ${lua_version}." >&2
    exit 1
  }
done

cd "$build_dir"
curl --fail --location --show-error --silent --output "$lua_archive" "$lua_url"
echo "${lua_sha256}  ${lua_archive}" | sha256sum --check --status
tar --extract --file "$lua_archive"

cd "lua-${lua_version}"
make linux

install -Dm755 src/lua /usr/local/bin/lua5.1
install -Dm755 src/luac /usr/local/bin/luac5.1
install -Dm644 src/liblua.a /usr/local/lib/liblua5.1.a
for header in lua.h luaconf.h lualib.h lauxlib.h; do
  install -Dm644 "src/${header}" "/usr/local/include/lua5.1/${header}"
done
install -Dm644 etc/lua.hpp /usr/local/include/lua5.1/lua.hpp

lua5.1 -e 'assert(_VERSION == "Lua 5.1")'
luac5.1 -v
