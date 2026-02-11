FROM ghcr.io/bootcrew/arch-bootc:latest
# Steal everything from here >:3c

# pacman config already done by arch-bootc

RUN pacman -Sy --noconfirm cosmic vulkan-asahi vulkan-broadcom vulkan-dzn vulkan-freedreno \
vulkan-gfxstream vulkan-intel vulkan-nouveau vulkan-panfrost vulkan-powervr vulkan-radeon \
vulkan-swrast vulkan-virtio glibc-locales
# All of this to avoid it downloading nvidia drivers (800+ mb x.x)
RUN pacman -S --clean --noconfirm

RUN systemctl enable cosmic-greeter.service

# https://github.com/bootc-dev/bootc/issues/1801
# it's already setup by the container we are based on

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /opt /mnt /var /usr/lib/sysimage/log && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var
# removed lines that arch-bootc already does

# Setup a temporary root passwd (toor) for dev purposes
#RUN pacman -S whois --noconfirm
RUN passwd -l root && useradd -m live && usermod -aG wheel live && passwd -d live

# https://bootc-dev.github.io/bootc/bootc-images.html#standard-metadata-for-bootc-compatible-images
LABEL containers.bootc 1

RUN bootc container lint
