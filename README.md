![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# MEDIKEEP
![size](https://img.shields.io/badge/image_size-156MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/medikeep?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-medikeep?color=7842f5">](https://github.com/11notes/docker-medikeep/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run medikeep, rootless and with no bloat.

# INTRODUCTION 📢

[medikeep](https://github.com/afairgiant/MediKeep) (created by [traah](https://www.reddit.com/user/traah/)) is a lightweight, self-hosted application for managing your personal medical information. Keep your health records organized and accessible while maintaining complete control over your data privacy.

![DASHBOARD](https://github.com/11notes/docker-medikeep/blob/master/img/Dashboard.png?raw=true)

# SYNOPSIS 📖
**What can I do with this?** This image will give you a [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and leightweight MediKeep installation. Perfect to store your medical records as safe as possible.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image is built and compiled from source
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/medikeep | 156MB | 1000:1000 | ❌ | amd64, arm64 |
| afairgiant/medikeep | 451MB | 0:0 | ❌ | amd64, arm64 |

# VOLUMES 📁
* **/medikeep/var** - Directory of all your uploads
* **/medikeep/backup (optional)** - Directory of your backups

# COMPOSE ✂️
```yaml
name: "medical"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  postgres:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-postgres
    image: "11notes/postgres:17"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
      POSTGRES_BACKUP_RETENTION: 5
    networks:
      backend:
    volumes:
      - "postgres.etc:/postgres/etc"
      - "postgres.var:/postgres/var"
      - "postgres.backup:/postgres/backup"
    tmpfs:
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    restart: "always"

  medikeep:
    depends_on:
      postgres:
        condition: "service_healthy"
        restart: true
    image: "11notes/medikeep:0.42.0"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      DB_PASSWORD: "${POSTGRES_PASSWORD}"
      SECRET_KEY: "${SECRET_KEY}"
      ADMIN_DEFAULT_PASSWORD: "${ADMIN_DEFAULT_PASSWORD}"
      SSO_ENABLED: true
      SSO_PROVIDER_TYPE: "keycloak"
      SSO_CLIENT_ID: "medikeep"
      SSO_CLIENT_SECRET: "${SSO_CLIENT_SECRET}"
      SSO_ISSUER_URL: "${SSO_ISSUER_URL}"
      SSO_REDIRECT_URI: "${SSO_REDIRECT_URI}"
    ports:
      - "3000:8080/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "medikeep.var:/medikeep/var"
      - "medikeep.backup:/medikeep/backup"
    tmpfs:
      - "/medikeep/log:uid=1000,gid=1000"
    restart: "always"

volumes:
  postgres.etc:
  postgres.var:
  postgres.backup:
  medikeep.var:
  medikeep.backup:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /medikeep | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [0.42.0](https://hub.docker.com/r/11notes/medikeep/tags?name=0.42.0)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:0.42.0``` you can use ```:0``` or ```:0.42```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/medikeep:0.42.0
docker pull ghcr.io/11notes/medikeep:0.42.0
docker pull quay.io/11notes/medikeep:0.42.0
```

# SOURCE 💾
* [11notes/medikeep](https://github.com/11notes/docker-medikeep)

# PARENT IMAGE 🏛️
* [${{ json_readme_parent_image }}](${{ json_readme_parent_url }})

# BUILT WITH 🧰
* [afairgiant/MediKeep](https://github.com/afairgiant/MediKeep)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-medikeep/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-medikeep/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-medikeep/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 18.12.2025, 06:27:04 (CET)*