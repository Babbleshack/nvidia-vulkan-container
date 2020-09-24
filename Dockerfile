FROM ubuntu:bionic AS vulkan-build

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libegl1-mesa-dev \
    libwayland-dev \
    libx11-xcb-dev \
    libxkbcommon-dev \
    libxrandr-dev \
    python3 \
    python3-distutils \
    wget && \
    rm -rf /var/lib/apt/lists/*


# Destination for built artefacts
RUN mkdir /built

# Python3 as default
RUN ln -s /usr/bin/python3 /usr/bin/python 

# Build and install VulkanHeader
RUN git clone https://github.com/KhronosGroup/Vulkan-Headers.git /opt/vulkan-headers \
&& cd /opt/vulkan-headers \
&& mkdir build && cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/built .. \
&& make install

# Build and install Vulkan-Loader
RUN git clone https://github.com/KhronosGroup/Vulkan-Loader.git /opt/vulkan-loader \
&& cd /opt/vulkan-loader \
&& mkdir build && cd build \
&& ../scripts/update_deps.py \
&& cmake -C helper.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/built .. \
&& cmake --build . --target install 
	
# Build and install Vulkan-Validation Layers
RUN git clone https://github.com/KhronosGroup/Vulkan-ValidationLayers.git /opt/vulkan \
&& cd /opt/vulkan \
&& mkdir build \
&& cd build \
&& ../scripts/update_deps.py \
&& cmake -C helper.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/built .. \
&& cmake --build . --target install 

# Build and install Vulkan-Tools
RUN git clone https://github.com/KhronosGroup/Vulkan-Tools.git /opt/vulkan-tools \
&& cd /opt/vulkan-tools \
&& mkdir build && cd build \
&& ../scripts/update_deps.py \
&& cmake -C helper.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/built .. \
&& cmake --build . --target install  


# Copy ICD file
RUN mkdir /work
COPY nvidia_icd.json /work/nvidia_icd.json 
COPY nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json

# Set workdir
WORKDIR /work

FROM nvidia/cudagl:11.0-devel-ubuntu18.04 AS vulkan-runtime

ENV NVIDIA_DRIVER_CAPABILITIES all

RUN apt-get update && apt-get install -y --no-install-recommends \
    libx11-xcb-dev \
    libxkbcommon-dev \
    libwayland-dev \
    libxrandr-dev \
    libegl1-mesa-dev && \
    rm -rf /var/lib/apt/lists/*

COPY --from=0 /built/include/* /usr/local/include/ 
COPY --from=0 /built/bin/* /usr/bin/
COPY --from=0 /built/lib/* /usr/local/lib/
COPY --from=0 /built/share/* /usr/local/share/

RUN ldconfig

COPY nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json
