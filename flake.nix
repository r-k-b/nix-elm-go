{
  description = "Nix package for lucamug/elm-go.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    elm-go-src = {
      url = "github:lucamug/elm-go?ref=master";
      flake = false;
    };
    nodeDependencies = {
      url = "path:node2nix";
      flake = false;
    };
  };

  outputs = { self, elm-go-src, nixpkgs, nodeDependencies, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        elm = pkgs.elmPackages.elm;
        nodejs = pkgs.nodejs_20;

        #        elm-go-pkg = pkgs.stdenv.mkDerivation {
        #          name = "elm-go";
        #          src = elm-go-src;
        #          buildInputs = [nodejs_20];
        #          installPhase = ''
        #            mkdir -p $out/bin
        #
        #          '';
        #
        #        };

        #        elm-go-pkg = pkgs.stdenv.mkDerivation {
        #          name = "elm-go";
        #          src = elm-go-src;
        #          buildInputs = [ nodejs_20 ];
        #          buildPhase = ''
        #            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
        #            export PATH="${nodeDependencies}/bin:$PATH"
        #
        #            mkdir -p $out/bin
        #
        #            # Build the distribution bundle in "dist"
        #            webpack
        #            cp -r dist $out/
        #          '';
        #        };

        #        nodeDependencies2 =
        #                    (import nodeDependencies { });
        #          (pkgs.callPackage (import nodeDependencies { }) { }).nodeDependencies;

        node2nixOutput =
          import nodeDependencies { inherit pkgs system nodejs; };

        #        elm-go-pkg = pkgs.writeScriptBin "elm-go" ''
        #          echo nodeDeps is ${nodeDependencies2}
        #          ln -s ${nodeDependencies2}/lib/node_modules ./node_modules
        #          export PATH="${nodeDependencies2}/bin:$PATH"
        #          ${pkgs.nodejs_20}/bin/node ${elm-go-src}/bin/elm-go.js "$@"
        #        '';

        nodeDeps = node2nixOutput.nodeDependencies;

        # based on https://johns.codes/blog/building-typescript-node-apps-with-nix
        # (try the "dream2nix" stuff later...)
        elm-go-pkg = pkgs.stdenv.mkDerivation {
          name = "elm-go";
          src = elm-go-src;
          buildInputs = [ nodejs ];
          buildPhase = ''
            runHook preBuild
            # symlink the generated node deps to the current directory for building
            ln -sf ${nodeDeps}/lib/node_modules ./node_modules
            export PATH="${nodeDeps}/bin:$PATH"

            # elm-go has no build step
            # npm run build

            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin

            # copy only whats needed for running the built app
            cp package.json $out/package.json
            cp -r lib $out/lib
            ln -sf ${nodeDeps}/lib/node_modules $out/node_modules

            # copy entry point, in this case our index.ts has the node shebang
            # nix will patch the shebang to be the node version specified in buildInputs
            # you could also copy in a script that is basically `npm run start`
            cp bin/elm-go.js $out/bin/elm-go
            chmod a+x $out/bin/elm-go

            runHook postInstall
          '';
        };

      in {
        devShell = pkgs.mkShell {
          name = "nix-elm-go-devshell";
          buildInputs = with pkgs; [ elm nix nixfmt node2nix nodejs ];
        };
        apps = {
          default = {
            type = "app";
            program = "${elm-go-pkg}/bin/elm-go";
          };
        };
        packages = {
          default = elm-go-pkg;
          elm-go = elm-go-pkg;
          elm-go-src = "${elm-go-src}";
        };
      });
}
