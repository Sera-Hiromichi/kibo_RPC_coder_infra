FROM ros:noetic

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3-pip python3-venv python3-dev python3-numpy python3-rospkg \
    git build-essential cmake curl ca-certificates sudo openssh-client \
    ros-noetic-rospy ros-noetic-actionlib ros-noetic-actionlib-msgs \
    ros-noetic-geometry-msgs ros-noetic-sensor-msgs ros-noetic-std-msgs \
    ros-noetic-message-generation ros-noetic-message-runtime ros-noetic-catkin \
    && rm -rf /var/lib/apt/lists/*

# Fetch the official packages at the version used by this development environment.
COPY workspace-image/fetch-official-sources.sh /usr/local/bin/fetch-official-sources
RUN bash /usr/local/bin/fetch-official-sources /opt/intball2_ws/src
RUN source /opt/ros/noetic/setup.bash && cd /opt/intball2_ws && catkin_make \
    && source devel/setup.bash \
    && python3 -c 'import rospy, actionlib, numpy, rospkg; import ib2_msgs.msg, platform_msgs.msg, platform_msgs.srv' \
    && find src -name '*.py' -exec chmod a+x {} +

ARG CODER_UID=1000
ARG CODER_GID=1000
RUN groupadd --gid "${CODER_GID}" coder \
    && useradd --uid "${CODER_UID}" --gid "${CODER_GID}" --create-home --shell /bin/bash coder \
    && echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder \
    && printf '\nsource /opt/intball2_ws/devel/setup.bash\nexport PATH="$HOME/.local/bin:$PATH"\n' >> /etc/skel/.bashrc \
    && cp /etc/skel/.bashrc /home/coder/.bashrc \
    && chown coder:coder /home/coder/.bashrc
USER coder
WORKDIR /home/coder
CMD ["bash"]
