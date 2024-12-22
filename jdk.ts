async function json<T>(url: string | URL): Promise<T> {
  const response = await fetch(url, {
    headers: {
      "Accept": "application/json",
    },
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.status}`);
  }

  return response.json() as T;
}

function normalizeVersion(version: string): string {
  return version.replace("+", "_");
}

const baseUrl = new URL("https://api.adoptium.net");

const { available_lts_releases: ltsReleases } = await json(
  new URL("/v3/info/available_releases", baseUrl),
);

const archMapping = {
  "x86_64": "x64",
  "x86_32": "x32",
};

const archMappingReverse = Object.fromEntries(
  Object.entries(archMapping).map(([k, v]) => [v, k]),
);

const rawArch = Deno.args[0] ?? "x86_64";
const architecture = archMapping[rawArch] ?? rawArch;

const wantedArchitectures = [
  "aarch64",
  "x64",
];

const wantedTypes = [
  "jre",
  "jdk",
];

const matrix = [];
for (const featureRelease of ltsReleases) {
  for (const architecture of wantedArchitectures) {
    for (const type of wantedTypes) {
      const url = new URL(
        `/v3/assets/feature_releases/${featureRelease}/ga`,
        baseUrl,
      );

      url.searchParams.set("architecture", architecture);
      url.searchParams.set("heap_size", "normal");
      url.searchParams.set("image_type", type);
      url.searchParams.set("os", "linux");
      url.searchParams.set("project", "jdk");
      //url.searchParams.set("vendor", "eclipse");

      url.searchParams.set("sort_order", "DESC");
      url.searchParams.set("sort_method", "DEFAULT");
      url.searchParams.set("page", "0");
      url.searchParams.set("page_size", "1");

      const res = await json(url);
      const release = res[0];
      const binary = release.binaries[0];

      const normalizedArch = archMappingReverse[architecture] ?? architecture;
      const normalizedVersion = normalizeVersion(
        release.version_data.openjdk_version,
      );

      const tag = `${binary.image_type}-${featureRelease}`;
      const specificTag = `${binary.image_type}-${normalizedVersion}`;

      const version = release.version_data.openjdk_version;
      const tarballUrl = binary.package.link;
      const checksum = binary.package.checksum;

      const releaseData = {
        featureRelease,
        githubReleaseUrl: release.release_link,
        majorName: tag,
        name: specificTag,
        type: binary.image_type,
        architecture: normalizedArch,
        version,
        versionSemver: release.version_data.semver,
        timestamp: release.timestamp,

        url: {
          binary: tarballUrl,
          checksum,
        },

        oci: {
          buildArgs: {
            JVM_DOWNLOAD_URL: tarballUrl,
            JVM_SHA256_CHECKSUM: checksum,
            JVM_VERSION: version,
          },
          tags: [
            specificTag,
            tag,
          ],
        },
      };
      matrix.push(releaseData);
    }
  }
}

console.log(JSON.stringify(matrix));
