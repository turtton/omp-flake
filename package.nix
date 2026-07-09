{
  lib,
  stdenvNoCC,
  stdenv,
  fetchurl,
  writeShellScript,
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
  };

  # Bun-compiled binaries hardcode /lib64/ld-linux-x86-64.so.2 which does
  # not exist on NixOS.  We cannot use autoPatchelfHook because patchelf
  # corrupts the embedded Bun payload.  Instead we leave the binary
  # untouched in libexec/ and wrap it via Nix's dynamic linker.
  linuxWrapper = writeShellScript "omp-wrapper" ''
    exec ${stdenv.cc.bintools.dynamicLinker} \
      --library-path ${lib.makeLibraryPath [ stdenv.cc.libc ]} \
      "$(dirname "$0")/../libexec/omp" "$@"
  '';

in
stdenvNoCC.mkDerivation {
  pname = "omp";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${src} $out/libexec/omp
    install -d $out/bin
    ${
      if stdenvNoCC.hostPlatform.isLinux then
        ''
          install -Dm755 ${linuxWrapper} $out/bin/omp
        ''
      else
        ''
          ln -s $out/libexec/omp $out/bin/omp
        ''
    }
    ln -s omp $out/bin/pi

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
