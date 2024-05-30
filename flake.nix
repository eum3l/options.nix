{
  description = "options.nix, a function for generating markdown documentation from nixos modules.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        lib.mkOptionScript = pkgs.callPackage (
          {
            path,
            nixosOptionsDoc,
            pkgs,
            writers,
            module,
            modulePrefix,
            optionsFile ? "OPTIONS.md",
          }:
          let
            src =
              (nixosOptionsDoc {
                inherit
                  (import (path + "/nixos/lib/eval-config.nix") {
                    specialArgs.pkgs = pkgs;
                    system = null;
                    modules = [ module ];
                  })
                  options
                  ;
              }).optionsJSON;
          in
          writers.writeNuBin "update-options.nu" ''
            open "${src}/share/doc/nixos/options.json" 
              | rotate
              | rename option name
              | where name starts-with "${modulePrefix}"
              | each {
                | i |
            $'
            ## ($i.name)
            ($i.option.description | str trim)
            ### Type
            ```
            ($i.option.type)
            ```(try {$"\n### Default\n```nix\n($i.option.default.text)\n```"})(try {$"\n### Example \n```nix\n($i.option.example.text)\n```"})
            ---
            '
              }
              | prepend "# Options"
              | str join " "
              | save -rf ${optionsFile} 
          ''
        );
      }
    );
}
