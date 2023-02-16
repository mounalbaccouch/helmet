#!/bin/bash
VCS_FILE="NOT_SET"

while getopts p:f:b: flag
do
    case "${flag}" in
        p) PULL_BOOL=${OPTARG};;
        f) VCS_FILE=${OPTARG};;
	b) BUILD_BOOL=${OPTARG};;
    esac
done

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install --no-install-recommends -y \
	bash-completion \
	build-essential \
	ca-certificates \
	ccache \
	cmake \
	curl \
	device-tree-compiler \
	dfu-util \
	file \
	gcc \
	gcc-multilib \
	g++-multilib \
	git \
	gperf \
	gnupg \
	gosu \
	htop \
	iproute2 \
	lcov \
	libasan6 \
	libmagic1 \
	libsdl2-dev \
	locales \
	lsb-release \
	make \
	menu \
	ninja-build \
	net-tools \
	openbox \
	pkg-config \
	python3-dev \
	python3-pip \
	python3-setuptools \
	python3-tk \
	python3-venv \
	python3-wheel \
	screen \
	terminator \
	unzip \
	valgrind \
	vim \
	wget \
	xz-utils

SCRIPT_PATH="$(dirname $(readlink -f $0))"
WORKSPACE_PATH="$(echo "$SCRIPT_PATH" | sed 's/\/helmet\/scripts//')"

# Setup west
if ! [ -f /opt/.venv-zephyr/bin/activate ]
then
	CURRENT_USER=`whoami`
	sudo mkdir /opt/.venv-zephyr
	sudo chown $CURRENT_USER:$CURRENT_USER /opt/.venv-zephyr
	python3 -m venv --prompt zephyr /opt/.venv-zephyr
	source /opt/.venv-zephyr/bin/activate
	pip install wheel
	pip install west
	pip install catkin-tools
	pip install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt
	pip3 check
	sudo chown $CURRENT_USER:$CURRENT_USER /opt/zephyr
	deactivate
	mkdir -p /home/$USER/bin
	ln -s /opt/.venv-zephyr/bin/west /home/$USER/bin/west
	cd $WORKSPACE_PATH
	echo -e "\033[1;32mSTATUS: west has been installed and linked."
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: west has already been installed and linked."
	echo -e "\033[0m"
fi

WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"
ZSDK_VERSION="0.15.2"

if ! [ -f /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/setup.sh ]
then
	sudo mkdir -p /opt/toolchains
	cd /opt/toolchains
	sudo wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64.tar.gz
	sudo tar xvf zephyr-sdk-${ZSDK_VERSION}_linux-x86_64.tar.gz
	cd /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
	sudo ./setup.sh
	sudo rm /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64.tar.gz
	sudo cp /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
	sudo udevadm control --reload
	cd $WORKSPACE_PATH
	echo -e "\033[1;32mSTATUS: zephyr sdk has been installed and linked."
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: zephyr sdk has already been installed and linked."
	echo -e "\033[0m"
fi

if ! [ -f /opt/zephyr/.west ]
then
	source /opt/.venv-zephyr/bin/activate
	pip install catkin-tools
	sudo mkdir -p /opt/zephyr
	cd /opt/zephyr
	west init --mr v3.2.0
	deactivate
	echo -e "\033[1;32mSTATUS: zephyr base has been installed."
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: zephyr base has already been installed."
	echo -e "\033[0m"
fi

if ! [ -d /opt/zeth ]
then
	sudo mkdir -p /opt/zeth
	sudo cp $SCRIPT_PATH/zeth.conf /opt/zeth
	sudo cp $SCRIPT_PATH/net-setup.sh /opt/zeth
	sudo chmod +x /opt/zeth/net-setup.sh
fi
if ! [ -f  /opt/zeth/zeth.conf ]
then
	sudo cp $SCRIPT_PATH/zeth.conf /opt/zeth
fi
if ! [ -f  /opt/zeth/net-setup.sh ]
then
	sudo cp $SCRIPT_PATH/net-setup.sh /opt/zeth
	sudo chmod +x /opt/zeth/net-setup.sh
fi

if ! [ -f /etc/apt/sources.list.d/ros2.list ]
then
	sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
fi

if ! [ -f /etc/apt/sources.list.d/gazebo-stable.list ]
then
	sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
fi

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install --no-install-recommends -y \
	ament-cmake \
	ros-humble-desktop \
	ros-humble-cyclonedds \
	ros-humble-gps-msgs \
	ros-humble-rmw-cyclonedds-cpp \
	python3-colcon-common-extensions \
	python3-colcon-ros \
	python3-jinja2 \
	python3-numpy \
	python3-vcstool \
	python3-xdg \
	python3-xmltodict \
	qt5dxcb-plugin \

pip3 install cyclonedds pycdr2 


# See if ends with EOF and add one if it does not.
if ! [[ $(tail -c1 "/home/$USER/.bashrc" | wc -l) -gt 0 ]]
then
	echo "" >> /home/$USER/.bashrc
fi

# Export zephyr toolchain variant if it does not exist.
if ! grep -qF "export ZEPHYR_TOOLCHAIN_VARIANT=zephyr" /home/$USER/.bashrc
then
	export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
	echo "export ZEPHYR_TOOLCHAIN_VARIANT=zephyr" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added ZEPHYR_TOOLCHAIN_VARIANT to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: ZEPHYR_TOOLCHAIN_VARIANT already in ~/.bashrc"
	echo -e "\033[0m"
fi

# Export zephyr sdk dir path if it does not exist.
if ! grep -qF "export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/" /home/$USER/.bashrc
then
	export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/
	echo "export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added ZEPHYR_SDK_INSTALL_DIR to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: ZEPHYR_SDK_INSTALL_DIR already in ~/.bashrc"
	echo -e "\033[0m"
fi

# Export zephyr base if it does not exist.
if ! grep -qF "export ZEPHYR_BASE=/opt/zephyr/zephyr" /home/$USER/.bashrc
then
	export ZEPHYR_BASE=/opt/zephyr/zephyr
	echo "export ZEPHYR_BASE=/opt/zephyr/zephyr" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added ZEPHYR_BASE to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: ZEPHYR_BASE already in ~/.bashrc"
	echo -e "\033[0m"
fi

# Source humble if it does not exist.
if ! grep -qF "source /opt/ros/humble/setup.bash" /home/$USER/.bashrc
then
	source /opt/ros/humble/setup.bash
	echo "source /opt/ros/humble/setup.bash" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added ROS2 Humble to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: ROS2 Humble already in ~/.bashrc"
	echo -e "\033[0m"
fi

# Source colcon arg complete if it does not exist.
if ! grep -qF "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" /home/$USER/.bashrc
then
	source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
	echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added colcon_argcomplete to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: colcon_argcomplete already in ~/.bashrc"
	echo -e "\033[0m"
fi

# Export cyclone if it does not exist.
if ! grep -qF "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" /home/$USER/.bashrc
then
	export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
	echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/$USER/.bashrc
	echo -e "\033[1;32mSTATUS: Added RMW_IMPLEMENTATION to ~/.bashrc"
	echo -e "\033[0m"
else
	echo -e "\033[1;32mSTATUS: RMW_IMPLEMENTATION already in ~/.bashrc"
	echo -e "\033[0m"
fi

eval "$( cat /home/$USER/.bashrc | tail -n +10)"

cd $WORKSPACE_PATH

if [ -f $WORKSPACE_PATH/helmet/$VCS_FILE ] 
then
	echo -e "\033[1;32mSTATUS: Performing vcs import with $VCS_FILE."
	echo -e "\033[0m"
	vcs import < $WORKSPACE_PATH/helmet/$VCS_FILE
elif [ -z ${PULL_BOOL} ]
then
	echo -e "\033[1;31mSTATUS: vcs import did not find valid VCS_FILE path to: $WORKSPACE_PATH/helmet/$VCS_FILE "
	echo -e "\033[1;31mSTATUS: please set VCS_FILE path correctly with -f option."
	echo -e "\033[0m"
elif ! [ -z ${PULL_BOOL} ]
then
	echo -e "\033[1;32mSTATUS: Performing a vcs pull."
	echo -e "\033[0m"
	vcs pull
fi

if [ -d $WORKSPACE_PATH/cerebri_workspace/cerebri ]
then
	if ! [ -f $/home/$USER/bin/cerebri ]
	then
		ln -s $WORKSPACE_PATH/cerebri_workspace/cerebri/build/zephyr/zephyr.elf /home/$USER/bin/cerebri
		echo -e "\033[1;32mSTATUS: symlinked $WORKSPACE_PATH/cerebri_workspace/cerebri/build/zephyr/zephyr.elf to /home/$USER/bin/cerebri"
		echo -e "\033[0m"
	else
		echo -e "\033[1;32mSTATUS: $WORKSPACE_PATH/cerebri_workspace/cerebri/build/zephyr/zephyr.elf already symlinked to /home/$USER/bin/cerebri"
		echo -e "\033[0m"
	fi
fi

if [ -d $WORKSPACE_PATH/cranium/src ]
then
	echo -e "\033[1;32mSTATUS: Building cranium."
	echo -e "\033[0m"
	cd $WORKSPACE_PATH/cranium
	colcon build --symlink-install
	echo -e "\033[1;32mSTATUS: cranium built."
	echo -e "\033[0m"

	# Source cranium logic if it does not exist.
	if ! grep -qF "source $WORKSPACE_PATH/cranium/install/setup.bash" /home/$USER/.bashrc
	then
		source $WORKSPACE_PATH/cranium/install/setup.bash
		cat << EOF >> /home/$USER/.bashrc
if [ -f $WORKSPACE_PATH/cranium/install/setup.bash ]; then
	source $WORKSPACE_PATH/cranium/install/setup.bash
fi
EOF
	fi
	cd $WORKSPACE_PATH
	eval "$( cat /home/$USER/.bashrc | tail -n +10)"
fi



if [ -d $WORKSPACE_PATH/gazebo/src ]
then
	# Export gz version if it does not exist.
	if ! grep -qF "export GZ_VERSION=garden" /home/$USER/.bashrc
	then
		echo "export GZ_VERSION=garden" >> /home/$USER/.bashrc
	fi
	
	eval "$( cat /home/$USER/.bashrc | tail -n +10)"
	
	if ! [ -f $WORKSPACE_PATH/gazebo/.gazebo_tools_installed ]
	then
		cd $WORKSPACE_PATH/gazebo/src
		sudo apt-get -y install \
		  $(sort -u $(find . -iname 'packages-'`lsb_release -cs`'.apt' -o -iname 'packages.apt' | grep -v '/\.git/') | sed '/gz\|sdf/d' | tr '\n' ' ')
		
		echo "" > $WORKSPACE_PATH/gazebo/.gazebo_tools_installed
	else
		echo -e "\033[1;32mSTATUS: Gazebo tools already installed."
		echo -e "\033[0m"
	fi

	echo -e "\033[1;32mSTATUS: Building Gazebo."
	echo -e "\033[0m"
	cd $WORKSPACE_PATH/gazebo
	colcon build --cmake-args -DBUILD_TESTING=OFF --merge-install
	echo -e "\033[1;32mSTATUS: Gazebo built."
	echo -e "\033[0m"

	# Export gz resources if it does not exist.
	if ! grep -qF "export GZ_SIM_RESOURCE_PATH=" /home/$USER/.bashrc
	then
		echo "export GZ_SIM_RESOURCE_PATH=$WORKSPACE_PATH/cranium/src/dream/models:$WORKSPACE_PATH/cranium/src/dream/worlds" >> /home/$USER/.bashrc
	else
		# If export does exist but does not have correct models path thow a warning to manually fix.
		if ! echo $GZ_SIM_RESOURCE_PATH | grep -qF "$WORKSPACE_PATH/cranium/src/dream/models"
		then
			echo -e "\033[0;31mWARNING!!! It appears you already have a GZ_SIM_RESOURCE_PATH but $WORKSPACE_PATH/cranium/src/dream/models is not in it!"
			echo -e "\033[0m"
		fi
		# If export does exist but does not have correct worlds path thow a warning to manually fix.
		if ! echo $GZ_SIM_RESOURCE_PATH | grep -qF "$WORKSPACE_PATH/cranium/src/dream/worlds"
		then
			echo -e "\033[0;31mWARNING!!! It appears you already have a GZ_SIM_RESOURCE_PATH but $WORKSPACE_PATH/cranium/src/dream/worlds is not in it!"
			echo -e "\033[0m"
		fi
	fi

	# Source gazebo logic if it does not exist.
	if ! grep -qF "source $WORKSPACE_PATH/gazebo/install/setup.bash" /home/$USER/.bashrc
	then
		source $WORKSPACE_PATH/gazebo/install/setup.bash
		cat << EOF >> /home/$USER/.bashrc
if [ -f $WORKSPACE_PATH/gazebo/install/setup.bash ]; then
	source $WORKSPACE_PATH/gazebo/install/setup.bash
fi
EOF
	fi
	cd $WORKSPACE_PATH
	eval "$( cat /home/$USER/.bashrc | tail -n +10)"
fi

if [ -d $WORKSPACE_PATH/electrode/src ]
then
	echo -e "\033[1;32mSTATUS: Building electrode."
	echo -e "\033[0m"
	cd $WORKSPACE_PATH/electrode
	source ~/.bashrc
	colcon build --symlink-install
	echo -e "\033[1;32mSTATUS: electrode built."
	echo -e "\033[0m"

	# Source electrode logic if it does not exist.
	if ! grep -qF "source $WORKSPACE_PATH/electrode/install/setup.bash" /home/$USER/.bashrc
	then
		source $WORKSPACE_PATH/electrode/install/setup.bash
		cat << EOF >> /home/$USER/.bashrc
if [ -f $WORKSPACE_PATH/electrode/install/setup.bash ]; then
	source $WORKSPACE_PATH/electrode/install/setup.bash
fi
EOF
	fi
	cd $WORKSPACE_PATH
	eval "$( cat /home/$USER/.bashrc | tail -n +10)"
fi

if [ -d $WORKSPACE_PATH/tools/src ]
then
	echo -e "\033[1;32mSTATUS: Building tools."
	echo -e "\033[0m"
	cd $WORKSPACE_PATH/tools
	source ~/.bashrc
	colcon build --symlink-install
	echo -e "\033[1;32mSTATUS: tools built."
	echo -e "\033[0m"

	# Source tools logic if it does not exist.
	if ! grep -qF "source $WORKSPACE_PATH/tools/install/setup.bash" /home/$USER/.bashrc
	then
		source $WORKSPACE_PATH/tools/install/setup.bash
		cat << EOF >> /home/$USER/.bashrc
if [ -f $WORKSPACE_PATH/tools/install/setup.bash ]; then
	source $WORKSPACE_PATH/tools/install/setup.bash
fi
EOF
	fi
	cd $WORKSPACE_PATH
	eval "$( cat /home/$USER/.bashrc | tail -n +10)"
fi
