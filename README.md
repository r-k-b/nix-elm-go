# why?

I wanted to use [lucamug/elm-go] from source through Nix, instead of just the
final tar file through npm.

[lucamug/elm-go]: https://github.com/lucamug/elm-go


# how?

```shell
$ nix run github:r-k-b/nix-elm-go
```

(Must have flakes enabled.)

Or, add it to your Flake inputs like:

```nix
inputs = {
  elm-go.url = "github:r-k-b/nix-elm-go";
};
```

and

```nix
devShell = pkgs.mkShell {
  name = "your-devshell";
  buildInputs = with pkgs; [
    elmPackages.elm
    inputs.nix-elm-go.packages.x86_64-linux.elm-go
  ];
};
```

Note, you'll need to provide your own Elm package.


# updating

run `./bin/update`, then commit the changed files.

Tip: with direnv enabled, `update` is already on your path.

Tip: if you're hacking on flake inputs like `path:node2nix` but the changes
aren't coming thru to `nix run` / `nix build`, it's probably because the cache
isn't being invalidated.  
Try `nix build .# --recreate-lock-file --refresh`.
