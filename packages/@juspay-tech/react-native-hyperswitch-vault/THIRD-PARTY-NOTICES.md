# Third-party notices

`@juspay-tech/react-native-hyperswitch-vault` is licensed under Apache-2.0 (see `LICENSE`).

## The package has no runtime dependencies

Nothing is installed alongside it. `react` and `react-native` are peer dependencies and always come
from the host application; they are never bundled. All three published entries — the merchant root
`.`, the checkout-SDK entry `./host`, and `./orchestration` — are built from this repository's own
source plus the one third-party component below.

## Bundled: hyperswitch-sdk-utils — Apache-2.0

Card validation and card-network detection are compiled from `hyperswitch-sdk-utils`, pinned in this
repository as the `shared-code` git submodule:

```
https://github.com/juspay/hyperswitch-sdk-utils.git
commit 1669cc28955bf547b7fe35d6401ea47720019ff9
```

It is **not vendored as a copy**: it is compiled from the pinned commit, and only the code the card
form actually reaches is emitted. That emitted code — the Luhn check, the issuer patterns, the CVC
length rules, the expiry rules — is present in `dist/esm/index.js` and `dist/cjs/index.js`, so it is
distributed with this package and is covered by this notice.

hyperswitch-sdk-utils is licensed under Apache-2.0, the same licence as this package. Its full
licence text is in the submodule at `shared-code/LICENCE`, and is the same text reproduced in this
repository's own `LICENSE`. Per section 4 of that licence, the copyright and attribution notices of
the original work are retained in the submodule and carried by this notice.

## Bundled: card-network artwork — trademarks of their respective owners

`dist/assets/` ships eleven images, each at @1x, @2x and @3x:

```
americanexpress  cartesbancaires  dinersclub  discover  interac  jcb  mastercard  visa
camera  cvv  waitcard
```

The card-network marks are rasterised at build time from the pinned submodule's approved artwork set
(`shared-code/assets/v2/icons`). Two non-network glyphs, the CVC hint and the scan-card camera, are
kept in this repository at `assets/source/`.

**These marks are the trademarks of their respective owners** — Visa, Mastercard, American Express,
Discover, JCB, Diners Club, Cartes Bancaires and Interac among them. They are included solely to
identify the card networks a customer may pay with. No licence to those trademarks is granted by
this package's Apache-2.0 licence, and their use is governed by each network's own brand
requirements. A merchant displaying them is responsible for complying with those requirements.

## Not distributed: the ReScript toolchain

This library is written in ReScript and compiled to JavaScript before publication. `rescript`
(LGPL-3.0-or-later, with the ReScript linking exception), `@rescript/core` (MIT), `@rescript/react`
and `rescript-react-native` are **development dependencies only**. A merchant installs none of them,
and the compiler is not distributed here.

The published bundles were checked for the ReScript runtime library and import none of it. There is
no `import` or `require` of any `Caml_*`, `Curry`, `Belt_*` or `Js_*` runtime module. What the
compiler does emit is the ordinary shape of generated code: the `RE_EXN_ID` exception tag, five
times, and one comment reading `/* Caml_exceptions Not a pure module */`. Both are compiler output,
not a copy of the runtime library. On that basis no runtime notice is required for the toolchain.

This is a recorded decision rather than an oversight. Re-check it if the compiler's output ever
begins importing runtime modules — `grep -E "(import|require)[^\n]*Caml" dist/esm/index.js` is the
check, and it must stay empty.

## Not distributed: anything else in this repository

The example application, its server, the build and verification scripts, and the test suites are not
part of the published package. Only `dist/`, `README.md`, `LICENSE` and this file are shipped; see
the `files` array in `package.json`.
