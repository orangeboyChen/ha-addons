# DDNS-GO Home Assistant Add-on

This add-on publishes `ghcr.io/orangeboychen/ha-addons-ddns-go`, a
multi-architecture image derived from the upstream
`ghcr.io/jeessy2/ddns-go` image.

## Home Assistant Ingress Patch

`patches/ha-ingress-auth.patch` is applied to the exact upstream release source
during the image build. When `DDNS_GO_HA_INGRESS=1` is set, the patch bypasses
ddns-go's cookie-based web login. Home Assistant has already authenticated the
request before forwarding it through Ingress, so the UI opens inside Home
Assistant instead of redirecting to ddns-go's `/login` page.

The bypass is limited to that explicit environment variable. A regular
upstream ddns-go image retains its normal login behavior.

## Runtime Options

`run.sh` reads `/data/options.json`, stores ddns-go configuration in
`/data/.ddns_go_config.yaml`, and starts the web interface on the internal
Ingress port. `frequency` controls the update interval. `pwd` is passed to
ddns-go's password-reset command before startup, so the stored application
password can be managed through the add-on options.

## Updating the Patch

When ddns-go changes its authentication implementation, rebuild the patch
against the new upstream tag and verify that opening the add-on through Home
Assistant Ingress no longer redirects to `/login`. Keep the patch focused on
the Ingress authentication boundary; do not disable normal authentication
unconditionally.

The source release tag and the upstream Docker image tag are separate build
inputs. `UPSTREAM_RELEASE_TAG` selects the source to patch, while
`UPSTREAM_IMAGE_TAG` selects the upstream runtime image and the published
`ha-addons-ddns-go` tag. They are deliberately not derived from one another.
Both arguments are required when building the Dockerfile.
