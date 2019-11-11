let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.13.4-20191025/packages.dhall sha256:f9eb600e5c2a439c3ac9543b1f36590696342baedab2d54ae0aa03c9447ce7d4

let overrides = {=}

let additions = {=}

in  upstream // overrides // additions
