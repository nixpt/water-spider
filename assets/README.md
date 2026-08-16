# Brand assets

The water-spider mark combines three ideas: a water strider, the ripple made as
it moves work between stations, and connected compute nodes. Cyan represents
transport and visibility, midnight navy represents infrastructure, and the
single orange node is a cost-safety checkpoint.

## Files

| File | Dimensions | Intended use |
|------|------------|--------------|
| `logo-master.png` | 1254 × 1254, transparent | Canonical raster master |
| `logo-{16,32,64,128,256,512}.png` | Named size, transparent | Favicons, avatars, and package surfaces |
| `favicon.ico` | 16–256, multi-resolution | Browser and desktop icon |
| `banner-master.png` | 2172 × 724 | Canonical wide artwork |
| `banner-1280x425.png` | 1280 × 425 | README and repository social preview |
| `source/logo-chroma.png` | 1254 × 1254 | Original generated logo before background removal |

Use `logo-512.png` for a GitHub or registry avatar and
`banner-1280x425.png` for GitHub's repository social preview. Keep the
transparent master when creating another size; do not upscale a small export.

## Provenance and regeneration

The logo and banner were generated with OpenAI's built-in image generation
tool on 2026-08-16. The logo prompt requested a centered, text-free geometric
water strider joined to a ripple and compute-node motif, in midnight navy,
electric cyan/teal, and a small safety-orange accent. It was generated against
a uniform magenta chroma background, then keyed to transparency with the
imagegen skill's `remove_chroma_key.py` helper.

The banner prompt used `logo-master.png` as its visual reference and requested
a text-free 3:1 midnight-navy repository header with the mark on the left and
subtle ripple/circuit paths extending into negative space. Standard logo sizes,
the favicon, and the 1280 × 425 banner were derived with ImageMagick.

When regenerating, preserve the text-free composition, palette, generous clear
space, tiny-size legibility, and the rule that the orange accent appears only
once.
