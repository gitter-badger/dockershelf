![](https://gitcdn.xyz/repo/LuisAlejandro/dockershelf/master/banner.svg)

---

[![](https://img.shields.io/github/release/LuisAlejandro/dockershelf.svg)](https://github.com/LuisAlejandro/dockershelf/releases) [![](https://img.shields.io/travis/LuisAlejandro/dockershelf.svg)](https://travis-ci.org/LuisAlejandro/dockershelf) [![](https://img.shields.io/docker/pulls/dockershelf/debian.svg)](https://hub.docker.com/r/dockershelf/debian) [![](https://img.shields.io/github/issues-raw/LuisAlejandro/dockershelf/in%20progress.svg?label=in%20progress)](https://github.com/LuisAlejandro/dockershelf/issues?q=is%3Aissue+is%3Aopen+label%3A%22in+progress%22) [![](https://badges.gitter.im/LuisAlejandro/dockershelf.svg)](https://gitter.im/LuisAlejandro/dockershelf) [![](https://cla-assistant.io/readme/badge/LuisAlejandro/dockershelf)](https://cla-assistant.io/LuisAlejandro/dockershelf)

## Debian shelf

[iwheezyl]: https://hub.docker.com/r/dockershelf/debian
[dwheezy]: https://img.shields.io/badge/-debian%2Fwheezy%2FDockerfile-blue.svg
[dwheezyl]: https://github.com/LuisAlejandro/dockershelf/blob/master/debian/wheezy/Dockerfile
[lwheezy]: https://images.microbadger.com/badges/image/dockershelf/debian:wheezy.svg
[lwheezyl]: https://microbadger.com/images/dockershelf/debian:wheezy

[ijessiel]: https://hub.docker.com/r/dockershelf/debian
[djessie]: https://img.shields.io/badge/-debian%2Fjessie%2FDockerfile-blue.svg
[djessiel]: https://github.com/LuisAlejandro/dockershelf/blob/master/debian/jessie/Dockerfile
[ljessie]: https://images.microbadger.com/badges/image/dockershelf/debian:jessie.svg
[ljessiel]: https://microbadger.com/images/dockershelf/debian:jessie

[istretchl]: https://hub.docker.com/r/dockershelf/debian
[dstretch]: https://img.shields.io/badge/-debian%2Fstretch%2FDockerfile-blue.svg
[dstretchl]: https://github.com/LuisAlejandro/dockershelf/blob/master/debian/stretch/Dockerfile
[lstretch]: https://images.microbadger.com/badges/image/dockershelf/debian:stretch.svg
[lstretchl]: https://microbadger.com/images/dockershelf/debian:stretch

[isidl]: https://hub.docker.com/r/dockershelf/debian
[dsid]: https://img.shields.io/badge/-debian%2Fsid%2FDockerfile-blue.svg
[dsidl]: https://github.com/LuisAlejandro/dockershelf/blob/master/debian/sid/Dockerfile
[lsid]: https://images.microbadger.com/badges/image/dockershelf/debian:sid.svg
[lsidl]: https://microbadger.com/images/dockershelf/debian:sid

![](https://gitcdn.xyz/repo/LuisAlejandro/dockershelf/master/table.svg)

|Image                                    |Release  |Dockerfile                |Layers                    |
|-----------------------------------------|---------|--------------------------|--------------------------|
|[`dockershelf/debian:wheezy`][iwheezyl]  |`wheezy` |[![][dwheezy]][dwheezyl]  |[![][lwheezy]][lwheezyl]  |
|[`dockershelf/debian:jessie`][ijessiel]  |`jessie` |[![][djessie]][djessiel]  |[![][ljessie]][ljessiel]  |
|[`dockershelf/debian:stretch`][istretchl]|`stretch`|[![][dstretch]][dstretchl]|[![][lstretch]][lstretchl]|
|[`dockershelf/debian:sid`][isidl]        |`sid`    |[![][dsid]][dsidl]        |[![][lsid]][lsidl]        |

![](https://gitcdn.xyz/repo/LuisAlejandro/dockershelf/master/table.svg)

## Building process

You can check out the Dockerfile for earch debian release at `debian/<release>/Dockerfile`.
The base filesystem is created with [`debian/build-image.sh`](https://github.com/LuisAlejandro/dockershelf/blob/master/debian/build-image.sh)

However, we explain the overall process here:

1. Built `FROM scratch`.
2. Labelled according to [label-schema.org](http://label-schema.org).
3. The base filesystem is built with `debootstrap` using the following command.

        debootstrap --verbose --variant minbase --arch amd64 --no-check-gpg --merged-usr <release> <dir> <mirror>

4. Then the following files are configured:

    * `/etc/resolv.conf`: DNS servers to be used (google).

            nameserver 8.8.8.8
            nameserver 8.8.4.4

    * `/etc/locale.gen`: Locales to be configured.

            # Dockershelf configuration for locale
            en_US.UTF-8 UTF-8

    * `/etc/apt/sources.list`: Content may vary depending on release. For example, sid does not have security updates.

            # Dockershelf configuration for apt sources
            deb <mirror> <release> main
            deb <mirror> <release>-updates main
            deb <security-mirror> <release>/updates main

    * `/etc/dpkg/dpkg.cfg.d/dockershelf`: Default options to pass to `dpkg`. Options here are like passing `--<option>` but without the double hiphens. Check out the [manpage for dpkg](http://manpages.ubuntu.com/manpages/trusty/man1/dpkg.1.html) for more information.

            # Dockershelf configuration for Dpkg

            # If a conffile has been deleted by the user and a new version of the
            # package wants to install it, let it do it.
            force-confmiss

            # If a package has a new version of a conffile but the user has modified it,
            # answer the question with the default option.
            force-confdef

            # If a package has a new version of a conffile but the user has modified it,
            # and there's no default option, replace the conffile with the new one.
            force-confnew

            # If a package tries to overwrite a file that exists in another package,
            # let it do it.
            force-overwrite

            # Don't call sync() for every IO operation.
            force-unsafe-io

    * `/etc/apt/apt.conf.d/dockershelf`: Default options passed to `apt`. Check out the [manpage for apt.conf](http://manpages.ubuntu.com/manpages/zesty/man5/apt.conf.5.html) and the [apt configuration index](http://sources.debian.net/src/apt/1.0.9.8.3/doc/examples/configure-index) for more information.

            # Dockershelf configuration for Apt

            # Disable creation of pkgcache.bin and srcpkgcache.bin to save space.
            Dir::Cache::pkgcache "";
            Dir::Cache::srcpkgcache "";

            # If there's a network error, retry up to 3 times.
            Acquire::Retries "3";

            # Don't download translations.
            Acquire::Languages "none";

            # Prefer download of gzipped indexes.
            Acquire::CompressionTypes::Order:: "gz";

            # Keep indexes gzipped.
            Acquire::GzipIndexes "true";

            # Don't install Suggests or Recommends.
            Apt::Install-Suggests "false";
            Apt::Install-Recommends "false";

            # Don't ask questions, assume 'yes'.
            Apt::Get::Assume-Yes "true";

            # Allow installation of unauthenticated packages.
            Apt::Get::AllowUnauthenticated "true";

            # Remove suggested and recommended packages on autoremove.
            Apt::AutoRemove::SuggestsImportant "false";
            Apt::AutoRemove::RecommendsImportant "false";

            # Cleaning post-hooks for dpkg and apt.
            Apt::Update::Post-Invoke { "/usr/share/dockershelf/clean-apt.sh"; };
            Dpkg::Post-Invoke { "/usr/share/dockershelf/clean-dpkg.sh"; };

    * `/etc/bash.bashrc`: Configure bash-completion and colorful prompt.

5. Install `iproute`, `inetutils-ping`, `locales`, `curl`, `ca-certificates` and `bash-completion` packages.
6. Configure locales.
7. Delete unnecessary files to shrink image.

## Made with :heart: and :hamburger:

![Banner](http://huntingbears.com.ve/static/img/site/banner.svg)

My name is Luis ([@LuisAlejandro](https://github.com/LuisAlejandro)) and I'm a Free and Open-Source Software developer living in Maracay, Venezuela.

If you like what I do, please support me on [Patreon](https://www.patreon.com/luisalejandro),  [Flattr](https://flattr.com/profile/luisalejandro), or donate via [PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=B8LPXHQY8QE8Y), so that I can continue doing what I love.

> Blog [huntingbears.com.ve](http://huntingbears.com.ve) · GitHub [@LuisAlejandro](https://github.com/LuisAlejandro) · Twitter [@LuisAlejandro](https://twitter.com/LuisAlejandro)