{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  versionData = lib.importJSON ./hashes.json;
  version = versionData.version;
  system = stdenvNoCC.hostPlatform.system;

  srcInfo =
    versionData.sources.${system}
    or (throw "Unsupported system: ${system}. Supported systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin");

  src = fetchurl {
    url = srcInfo.url;
    hash = srcInfo.hash;
    executable = true;
  };

in
stdenvNoCC.mkDerivation {
  pname = "omp";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${src} $out/bin/omp

    # omp alias for compatibility with the upstream binary name.
    ln -s $out/bin/omp $out/bin/omp

    runHook postInstall
  '';

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management (Oh My Pi)";
    homepage = "https://omp.sh";
    changelog = "https://github.com/can1357/oh-my-pi/releases";
    downloadPage = "https://github.com/can1357/oh-my-pi/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames versionData.sources;
    mainProgram = "omp";
  };
}
