FROM osrf/ros:noetic-desktop-full-focal
#FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_GEOMETRY=1920x1080
ENV VNC_DEPTH=24

ARG USER_NAME=user
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG ARCH=amd64
ENV USER_NAME=${USER_NAME}

# Emoji + UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-color-emoji locales \
 && rm -rf /var/lib/apt/lists/*

# Generate UTF-8 locale
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    xterm dbus-x11 \
    mesa-utils libgl1-mesa-dri \
    xauth x11-utils \
    fonts-dejavu policykit-1 \
    ca-certificates wget nano less unzip \
    elementary-xfce-icon-theme adwaita-icon-theme hicolor-icon-theme \
    thunar-volman gvfs gvfs-backends tumbler \
    file-roller xarchiver unzip p7zip-full tar bzip2 \
    firefox \
    && rm -rf /var/lib/apt/lists/*

# --- Create desktop entry for Firefox (with --no-sandbox) ---
RUN mkdir -p /usr/share/applications && \
    cat > /usr/share/applications/firefox-nosandbox.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox (No Sandbox)
Comment=Browse the Web
Exec=firefox --no-sandbox %u
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

# --- Make it default browser ---
RUN xdg-settings set default-web-browser firefox-nosandbox.desktop || true

# Install some handy tools.
RUN set -x \
    && apt-get update \
    && apt-get --with-new-pkgs upgrade -y \
    && apt-get install -y mesa-utils \ 
    && apt-get install -y iputils-ping \ 
    && apt-get install -y apt-transport-https ca-certificates \
    && apt-get install -y openssh-server python3-pip exuberant-ctags \
    && apt-get install -y git vim tmux nano htop sudo curl wget gnupg2 \
    && apt-get install -y bash-completion \
    && apt-get install -y libcanberra-gtk3-0 \
    && apt-get install -y ros-noetic-turtlebot3 \
    && apt-get install -y ros-noetic-turtlebot3-bringup ros-noetic-turtlebot3-description \
    && apt-get install -y ros-noetic-turtlebot3-example ros-noetic-turtlebot3-gazebo \
    && apt-get install -y ros-noetic-turtlebot3-msgs ros-noetic-turtlebot3-navigation \
    && apt-get install -y ros-noetic-turtlebot3-simulations \
    && apt-get install -y ros-noetic-turtlebot3-slam ros-noetic-turtlebot3-teleop \
    && apt-get install -y ros-noetic-gmapping ros-noetic-slam-gmapping ros-noetic-openslam-gmapping \
    && pip3 install powerline-shell==0.7.0 dearpygui==2.1.0 \
    && rm -rf /var/lib/apt/lists/* 

# Copy CascadiaMono Nerd Font zip into the image and install
COPY CascadiaMono.zip /tmp/CascadiaMono.zip
RUN mkdir -p /usr/share/fonts/truetype/nerdfonts && \
    unzip -q /tmp/CascadiaMono.zip -d /usr/share/fonts/truetype/nerdfonts/CascadiaMono && \
    fc-cache -fv && \
    rm -f /tmp/CascadiaMono.zip

# Install yolo v8
#RUN pip3 install ultralytics==8.0.178

RUN set -x \
	&& apt-get update \
    && apt-get install -y ros-noetic-multi-map-server ros-noetic-multirobot-map-merge \
	&& apt-get install -y ros-noetic-hector-sensors-gazebo \
	&& rm -rf /var/lib/apt/lists/* 

# The OSRF contianer didn't link python3 to python, causing ROS scripts to fail.
RUN ln -s /usr/bin/python3 /usr/bin/python


# Optional: VirtualGL (if GPU passthrough is needed)
RUN wget -O /tmp/virtualgl.deb https://github.com/VirtualGL/virtualgl/releases/download/3.1.3/virtualgl_3.1.3_${ARCH}.deb \
 && dpkg -i /tmp/virtualgl.deb || true \
 && apt-get -y -f install \
 && rm -f /tmp/virtualgl.deb

# Create non-root user
RUN groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USER_NAME} \
    && echo "user:user" | chpasswd && adduser user sudo \
    && echo "user ALL=(ALL) NOPASSWD: ALL " >> /etc/sudoers \
    && mkdir -p /home/${USER_NAME}/.vnc \
    && touch /home/${USER_NAME}/.Xauthority \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# (Optional) prevent screen lockers from interfering
RUN apt-get purge -y light-locker xfce4-screensaver || true \
 && rm -f /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/xfce4-screensaver.desktop || true

# Startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh && chown ${USER_NAME}:${USER_NAME} /usr/local/bin/startup.sh


USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

RUN sudo usermod -a -G video user


RUN git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack  \
        && git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux-resurrect
COPY --chown=user:user ./.tmux.conf /home/user/.tmux.conf
COPY --chown=user:user ./.powerline.sh /home/user/.powerline.sh

# Configure xfce4-terminal to use Cascadia Mono Nerd Font
RUN mkdir -p /home/${USER_NAME}/.config/xfce4/terminal && \
    cat > /home/${USER_NAME}/.config/xfce4/terminal/terminalrc <<'EOF'
[Configuration]
FontName=CaskaydiaMono Nerd Font Mono 12
ColorForeground=#d0d0d0
ColorBackground=#1c1c1c
ScrollingUnlimited=TRUE
EOF

# Pre-seed XFCE workspace config to 1 desktop
RUN mkdir -p /home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="workspace_count" type="int" value="1"/>
  </property>
</channel>
EOF

# Set some decent colors if the container needs to be accessed via /bin/bash.
RUN echo LS_COLORS=$LS_COLORS:\'di=1\;33:ln=36\' >> ~/.bashrc \
        && echo export LS_COLORS >> ~/.bashrc \
        && echo 'source ~/.powerline.sh' >> ~/.bashrc \
        && echo 'alias tmux="tmux -2"' >> ~/.bashrc \
        && echo 'PATH=~/bin:$PATH' >> ~/.bashrc \
        && touch ~/.sudo_as_admin_successful # To surpress the sudo message at run.

RUN rosdep update \
        && echo "source /opt/ros/noetic/setup.bash" >> /home/user/.bashrc


# Adding the ardrone
RUN mkdir -p Projects/ardrone_ws/src 
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws; catkin_make'
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws; catkin_make'

RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws/src; git clone https://github.com/PXLRoboticsLab/ardrone_autonomy.git'
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws/src; git clone https://github.com/PXLRoboticsLab/ardrone_gazebo.git'

RUN echo "source /home/user/Projects/ardrone_ws/devel/setup.bash --extend" >> /home/user/.bashrc

RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws/; . ./devel/setup.bash; catkin_make -j1'
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/ardrone_ws/; . ./devel/setup.bash; catkin_make -j1'

# Adding a workspace for the students.
RUN mkdir -p Projects/catkin_ws/src 
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/catkin_ws; catkin_make'
RUN /bin/bash -c '. /opt/ros/noetic/setup.bash; cd /home/user/Projects/catkin_ws; catkin_make'


RUN echo "source /home/user/Projects/catkin_ws/devel/setup.bash --extend" >> /home/user/.bashrc


EXPOSE 5901
CMD ["/usr/local/bin/startup.sh"]
