{
  description = "options.nix, a function for generating markdown documentation from nixos modules.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    { self, nixpkgs }:
    {
      lib.mkOptionScript =
        {
          system,
          module,
          modulePrefix,
          optionsFile ? "OPTIONS.md",
        }:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.callPackage (
          {
            path,
            nixosOptionsDoc,
            writers,
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
        ) { };
    };
}
