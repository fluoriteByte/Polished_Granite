image_name := env("BUILD_IMAGE_NAME", "polished_granite")
image_tag := env("BUILD_IMAGE_TAG", "uncut")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")
base_image_url := `grep 'FROM' Containerfile | sed 's/FROM\s//;s/:.*//'`
export SOURCE_DATE_EPOCH := `git show -s --format=%ct HEAD`
[private]
_sudo := `command -v sudo || command -v pkexec || command -v run0`
container_runtime := env("CONTAINER_RUNTIME", `command -v podman >/dev/null 2>&1 && echo podman || echo docker`)

trust_base_image:
    {{ _sudo }} podman image trust set -t accept "{{ base_image_url }}"

build-containerfile $image_name=image_name:
    mkdir -p local_cache
    {{ _sudo }} {{ container_runtime }} build \
        --rewrite-timestamp \
        -f Containerfile \
        -t "{{ image_name }}:{{ image_tag }}" . \
        -v `pwd`/local_cache:/usr/lib/sysimage/cache/pacman/pkg/:z

bootc *ARGS:
    {{ _sudo }} {{ container_runtime }} run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -e RUST_LOG=debug \
        -v "{{ base_dir }}:/data" \
        --security-opt label=type:unconfined_t \
        "{{ image_name }}:{{ image_tag }}" bootc {{ ARGS }}

generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${base_dir}/bootable.img" ] ; then
        fallocate -l 20G "${base_dir}/bootable.img"
    fi
    just bootc install to-disk --composefs-backend --via-loopback \
        /data/bootable.img --filesystem "${filesystem}" --wipe --bootloader systemd
