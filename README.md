# embedded-workflows
Store embedded software workflows.
Do not forget this is **PUBLIC** repository.

Implemented Reusable Workflows:

- **Prepare Environment** (prepare_env.yml): By parsing the github context, it sets the variables `RELEASE_VERSION` and `RELEASE_REPO` for the next workflows.
The `RELEASE_VERSION` will be `999.999.999` for a regular commit to a non-master branch. For a merge to a master branch, it will get the nightly build format `<yyyy.mm.dd>-merge-<branch>`. For a tag in a branch, it will take the tag version (if properly formatted).
The `RELEASE_REPO` will have the Cloudsmith target repository to upload the package: `night-builds` for a merge to a master branch, `packages-released` for a tag without the `-dev` in a master branch suffix and `packages-dev` for a tag with the `-dev` suffix in a non-master branch.
If the `BUILD_DOCKER_CACHE` input boolean is set to `true`, it will also login in the `Github Container Registry` and call `build_for_ultimaker.sh -a build_docker_cache` in order to cache the docker image. This technique is currently used by (and can be copied from) `Opinicus` to cache the docker image.

- **Shellcheck** (shellcheck.yml): Call `./build_for_ultimaker.sh -a shellcheck` for the repository.
- **Build Package** (build.yml): Uses the `RELEASE_VERSION` from *Prepare Environment* to make a package by calling `./build_for_ultimaker.sh -a build`. The resulting package is uploaded as an artifact.
- **Unit Test** (unit_test.uml): Might be used to run the unit tests for the repository if this can be encapsulated using `./build_for_ultimaker.sh -a unittest`.
- **Release Package** (release_pkg.yml): Downloads the artifact generated in the *Build Package* workflow and uploads to Cloudsmith in the repository defined by `RELEASE_REPO`. It will only run if `RELEASE_REPO` is not `none`.
- **Release Docker Image** (release_docker_img.yml): Build and Release to Github Packages a docker image. You need to specify two inputs to this workflow: The docker image name (like `um-kernel` or `ultimoco`) and the tag prefix used to trigger the docker image build, e.g. `docker_img-`. In this case, if we tag the repository with `docker_img-v1`, the prefix will be stripped and the image will be released as version `v1`. **VERY IMPORTANT:** After upload, the image will be *INTERNAL* and NOT connected to any repository. You need to select the package in organizarion (Ultimaker->Packages->`package name`->Connect Repository) and make it *PUBLIC* (Ultimaker->Packages->`package name`->Package Settings->Change Visibility) because our workflows do not authenticate before downloading images - we dont store any private information in the docker images. It is also optional to *connect* the package to a repository. According to the current Github documentation, connecting a package to a public repository will not count its downloads from the organization bandwitdh, so it is a good idea doing so. The current procedure is to connect the package to this repo (`embedded-workflows`) and make it Public. 

This repository also stores the Dockerfiles to build the images used by CI Linting Tools. These images are pushed to the Gitlab Packages repository (https://github.com/orgs/Ultimaker/packages?tab=packages)

- **Clang-Format:** Dockerfiles/clang-format/
- **Clang-Tidy:** Dockerfiles/clang-tidy/
- **CPPCheck:** Dockerfiles/cppcheck/
