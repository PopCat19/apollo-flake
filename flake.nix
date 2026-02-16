{
  description = "Apollo is a Game stream host for Moonlight";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # Provides both regular and unfree nixpkgs instances
      # Unfree is needed only for CUDA packages
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
            pkgsUnfree = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          in
          f { inherit pkgs pkgsUnfree; }
        );

      sunshinePackage =
        {
          pkgs,
          cudaSupport ? pkgs.config.cudaSupport or false,
          cudaPackages ? pkgs.cudaPackages,
        }:
        let
          stdenv' = if cudaSupport then cudaPackages.backendStdenv else pkgs.stdenv;
          # Pre-fetch the boost dependency to circumvent the problem with boost188 package.
          # This relies on CMakeLists FetchContent
          boostVersion = "1.88.0";
          boostCMakeTarballURL = "https://github.com/boostorg/boost/releases/download/boost-${boostVersion}/boost-${boostVersion}-cmake.tar.xz";

          boostFetchedTarball = pkgs.fetchurl {
            url = boostCMakeTarballURL;
            hash = "sha256-9ItIOQOAz7lKYphyNG46gTcNxJiJbxYBmt5yercusew=";
          };

          boostExtractedSrc =
            pkgs.runCommand "boost-${boostVersion}-cmake-src"
              {
                src = boostFetchedTarball;
                nativeBuildInputs = [
                  pkgs.gnutar
                  pkgs.xz
                ];
              }
              ''
                mkdir -p $out
                # Extract and strip the top-level directory (e.g., "boost-1.88.0-cmake/")
                # so $out contains the contents of that directory (CMakeLists.txt, libs/, etc.)
                tar -xf $src --strip-components=1 -C $out
              '';

          # Runtime dependencies for RPATH wrapping
          runtimeDeps = with pkgs; [
            avahi
            libgbm
            libglvnd
            xorg.libXrandr
            xorg.libxcb
          ];

          # Build dependencies
          buildDeps = with pkgs; [
            amf-headers
            avahi
            curl
            glib
            libcap
            libdatrie
            libdrm
            libepoxy
            libevdev
            libffi
            libgbm
            libnotify
            libopus
            libpulseaudio
            libselinux
            libsepol
            libthai
            libuuid
            libva
            libvdpau
            libxkbcommon
            miniupnpc
            nlohmann_json
            numactl
            openssl
            pcre
            pcre2
            svt-av1
            sysprof
            wayland
            xorg.libX11
            xorg.libXdmcp
            xorg.libXfixes
            xorg.libXi
            xorg.libXrandr
            xorg.libXtst
            xorg.libxcb
            (if pkgs.lib ? libappindicator then pkgs.libappindicator else pkgs.libappindicator-gtk3)
          ];

          # CUDA-specific dependencies
          cudaDeps = with cudaPackages; [
            cuda_cudart
            cudatoolkit
          ];
        in
        stdenv'.mkDerivation rec {
          pname = "sunshine";
          version = "master";
          src = pkgs.fetchFromGitHub {
            owner = "ClassicOldSong";
            repo = "Apollo";
            rev = "5af771d29e986e3604cf74b51ac81cba5b0bd3ee";
            hash = "sha256-PWlXoYa6B7yVRwhS32uG51ktG11pifgzgVspchR/W1I=";
            fetchSubmodules = true;
          };

          # build webui
          ui = pkgs.buildNpmPackage {
            inherit src version;
            pname = "apollo-ui";
            npmDepsHash = "sha256-OM3LB8SUX5C5tnyb00amFtfePoLrRumLpAl05Ur9Rz4=";

            postPatch = ''
              cp ${./package-lock.json} ./package-lock.json
            '';

            installPhase = ''
              mkdir -p $out
              cp -r * $out/
            '';
          };

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.pkg-config
            pkgs.python3
            pkgs.makeWrapper
            pkgs.wayland-scanner
            pkgs.autoPatchelfHook
          ]
          ++ pkgs.lib.optionals cudaSupport [
            pkgs.autoAddDriverRunpath
            cudaPackages.cuda_nvcc
            (pkgs.lib.getDev cudaPackages.cuda_cudart)
          ];

          buildInputs = buildDeps ++ pkgs.lib.optionals cudaSupport cudaDeps;

          runtimeDependencies = runtimeDeps;

          cmakeFlags = [
            "-Wno-dev"
            (pkgs.lib.cmakeBool "UDEV_FOUND" true)
            (pkgs.lib.cmakeBool "SYSTEMD_FOUND" true)
            (pkgs.lib.cmakeFeature "UDEV_RULES_INSTALL_DIR" "lib/udev/rules.d")
            (pkgs.lib.cmakeFeature "SYSTEMD_USER_UNIT_INSTALL_DIR" "lib/systemd/user")
            (pkgs.lib.cmakeBool "BOOST_USE_STATIC" false)
            (pkgs.lib.cmakeBool "BUILD_DOCS" false)
            (pkgs.lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "nixpkgs")
            (pkgs.lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://nixos.org")
            (pkgs.lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/NixOS/nixpkgs/issues")
            "-DFETCHCONTENT_SOURCE_DIR_BOOST=${boostExtractedSrc}"
          ]
          ++ pkgs.lib.optionals (!cudaSupport) [
            (pkgs.lib.cmakeBool "SUNSHINE_ENABLE_CUDA" false)
          ];

          env = {
            # needed to trigger CMake version configuration
            BUILD_VERSION = "${version}";
            BRANCH = "master";
            COMMIT = "";
          };

          postPatch = ''
            substituteInPlace cmake/packaging/linux.cmake \
              --replace-fail 'find_package(Systemd)' "" \
              --replace-fail 'find_package(Udev)' ""

            substituteInPlace cmake/targets/common.cmake \
              --replace-fail 'find_program(NPM npm REQUIRED)' ""

            substituteInPlace packaging/linux/dev.lizardbyte.app.Sunshine.desktop \
              --subst-var-by PROJECT_NAME 'Sunshine' \
              --subst-var-by PROJECT_DESCRIPTION 'Self-hosted game stream host for Moonlight' \
              --subst-var-by SUNSHINE_DESKTOP_ICON 'sunshine' \
              --subst-var-by CMAKE_INSTALL_FULL_DATAROOTDIR "$out/share" \
              --replace-fail '/usr/bin/env systemctl start --u sunshine' 'sunshine'

            substituteInPlace packaging/linux/sunshine.service.in \
              --subst-var-by PROJECT_DESCRIPTION 'Self-hosted game stream host for Moonlight' \
              --subst-var-by SUNSHINE_EXECUTABLE_PATH $out/bin/sunshine \
              --replace-fail '/bin/sleep' '${pkgs.lib.getExe' pkgs.coreutils "sleep"}'
          '';

          preBuild = ''
            cp -r ${ui}/build ../
          '';

          buildFlags = [
            "sunshine"
          ];

          postFixup = pkgs.lib.optionalString cudaSupport ''
            wrapProgram $out/bin/sunshine \
              --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath [ pkgs.vulkan-loader ]}
          '';

          installPhase = ''
            runHook preInstall
            cmake --install .
            runHook postInstall
          '';

          postInstall = ''
            install -Dm644 ../packaging/linux/dev.lizardbyte.app.Sunshine.desktop $out/share/applications/${pname}.desktop
          '';

          meta = with pkgs.lib; {
            description = "Apollo is a Game stream host for Moonlight";
            homepage = "https://github.com/ClassicOldSong/Apollo";
            license = licenses.gpl3Only;
            mainProgram = "sunshine";
            maintainers = with maintainers; [ nil-andreas ];
            platforms = platforms.linux;
          };
        };
    in
    {
      # System-independent (fixes #4)
      nixosModules.default =
        { pkgs, ... }:
        {
          imports = [ ./apollo-module.nix ];
          services.apollo.package = nixpkgs.lib.mkDefault self.packages.${pkgs.system}.default;
        };

      # System-dependent
      packages = forEachSystem (
        { pkgs, pkgsUnfree }:
        {
          default = sunshinePackage { inherit pkgs; };
          sunshine = sunshinePackage { inherit pkgs; };
          sunshine-cuda = sunshinePackage {
            pkgs = pkgsUnfree;
            cudaSupport = true;
          };
        }
      );

      apps = forEachSystem (
        { pkgs, ... }:
        {
          default = {
            type = "app";
            program = "${self.packages.${pkgs.system}.default}/bin/sunshine";
          };
          sunshine = self.apps.${pkgs.system}.default;
          sunshine-cuda = {
            type = "app";
            program = "${self.packages.${pkgs.system}.sunshine-cuda}/bin/sunshine";
          };
        }
      );

      devShells = forEachSystem (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${pkgs.system}.default ];
            packages = [
              pkgs.cmake
              pkgs.gdb
            ];
          };
        }
      );
    };
}
