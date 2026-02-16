# Apollo nix flake

Nix flake for https://github.com/ClassicOldSong/Apollo.

> **Note:** This project contains LLM-generated contributions. Use with caution and review changes before deploying.

## Disclaimer
This is the first flake I'm building. It might not be complete. Following the Usage section you should be able to get Apollo up and running.

## Usage
To include the flake, follow the instructions [Using nix flakes with NixOS](https://nixos.wiki/wiki/flakes#Using_nix_flakes_with_NixOS). After including the flake, add the module to your NixOS configuration:

```nix
{
  inputs.apollo-flake.url = "github:popcat19/apollo-flake";

  outputs = { self, nixpkgs, apollo-flake, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        apollo-flake.nixosModules.default
        {
          services.apollo.enable = true;
          # package is auto-set from the flake, but can be overridden:
          # services.apollo.package = apollo-flake.packages.x86_64-linux.default;
        }
      ];
    };
  };
}
```

And in my `configuration.nix`:
```nix
  # Enable self-hosted game streaming
  services.apollo = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      apps = [
        {
          name = "TV";
          prep-cmd = [
            {
              do = ''
              ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-2,3840x2160@60,0x0,1
              '';
              undo = ''
                ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-2,5120x1440@240,0x0,1
              '';
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };
  };
```

After `nixos-rebuild` the service should be started. Verify with `systemctl --user status apollo` or start it with `systemctl --user start apollo.service`

## Credits

- Original project: [ClassicOldSong/Apollo](https://github.com/ClassicOldSong/Apollo)
- Sunshine package: Modified from [nixpkgs](https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/su/sunshine/package.nix) — thanks to the Sunshine package maintainers for their work
- Refactoring: LLM-assisted with human review
