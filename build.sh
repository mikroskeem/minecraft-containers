#!/usr/bin/env bash
set -euo pipefail
set -x

jdks="$(
jq -c '[.[] | select(.architecture == "aarch64") | { name, version, url: .url.binary, sha256: .url.checksum }]' < jdks.json
)"

img="localhost/zentria/jvm"

while read -r _jdk; do
	tag="$(jq -cer '.name' <<< "${_jdk}")"
	version="$(jq -cer '.version' <<< "${_jdk}")"
	url="$(jq -cer '.url' <<< "${_jdk}")"
	sha256="$(jq -cer '.sha256' <<< "${_jdk}")"

	docker build --build-arg=JVM_DOWNLOAD_URL="${url}" --build-arg=JVM_SHA256_CHECKSUM="${sha256}" --build-arg=JVM_VERSION="${version}" --tag="${img}:${tag}" .
done < <(jq -c '.[]' <<< "${jdks}")
