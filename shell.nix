let
  pkgs = import <nixpkgs>{};
in
pkgs.mkShell {
  name = "ep-bash-worker";
  buildInputs = [
    pkgs.curl
    pkgs.ffmpeg
    pkgs.jq
  ];
}
